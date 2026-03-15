/**
 * Pinch — per-project plugin manager for pi
 *
 * Manages Claude plugins from git repos declared in pinch.json manifests.
 * Global manifest: ~/.pi/agent/pinch.json
 * Project manifest: .pi/pinch.json (overrides global by name)
 *
 * Repos are cloned directly into the project at
 * .pi/pinch/<source>/. Skills found in installed plugins are registered
 * via resources_discover.
 *
 * NOTE: An XDG-based shared cache with symlinks into the project would be
 * cleaner, but these paths need to work inside bind-mounted containers
 * where symlinks pointing outside the mount don't resolve. Hardlinks
 * can't span filesystems and don't work on directories. So we clone
 * directly into the project tree.
 *
 * Manifest format (pinch.json):
 *
 *   {
 *     "anthropic": {
 *       "repo": "https://github.com/anthropics/claude-plugins-official",
 *       "ref": "main",
 *       "plugins": ["claude-md-management", "skill-creator"]
 *     },
 *     "my-plugins": {
 *       "repo": "git@github.com:me/plugins.git",
 *       "ref": "v1.2.0",
 *       "path": "plugins",
 *       "plugins": ["my-plugin"]
 *     }
 *   }
 *
 * Plugin structure (Claude plugin convention):
 *
 *   <plugin>/
 *     .claude-plugin/plugin.json
 *     skills/<skill-name>/SKILL.md
 *
 * Commands:
 *   /pinch:install  — clone/fetch all sources, register skills
 *   /pinch:update   — pull latest for unpinned sources
 *   /pinch:status   — show installed plugins and their skills
 *
 * Lock file (.pi/pinch-lock.json) tracks exact commits per source.
 * Repos live in .pi/pinch/<source-name>/.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import * as child_process from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

// ── Types ──────────────────────────────────────────────────────────────

interface PinchSource {
  repo: string;
  ref?: string;
  path?: string; // subdirectory containing plugins (e.g. "plugins")
  plugins: string[];
}

interface PinchConfig {
  [name: string]: PinchSource;
}

interface PinchLockEntry {
  commit: string;
  ref?: string;
}

interface PinchLock {
  [name: string]: PinchLockEntry;
}

// ── Paths ──────────────────────────────────────────────────────────────

function pinchDir(cwd: string): string {
  return path.join(cwd, ".pi", "pinch");
}

function repoDir(cwd: string, name: string): string {
  return path.join(pinchDir(cwd), name);
}

function globalManifestPath(): string {
  return path.join(os.homedir(), ".pi", "agent", "pinch.json");
}

function projectManifestPath(cwd: string): string {
  return path.join(cwd, ".pi", "pinch.json");
}

function lockPath(cwd: string): string {
  return path.join(cwd, ".pi", "pinch-lock.json");
}

// ── Manifest / Lock ───────────────────────────────────────────────────

function readManifest(filePath: string): PinchConfig | null {
  if (!fs.existsSync(filePath)) return null;
  try {
    const raw = JSON.parse(fs.readFileSync(filePath, "utf-8"));
    if (!raw || typeof raw !== "object") return null;
    for (const v of Object.values(raw)) {
      if (typeof v === "object" && v !== null && "repo" in (v as any)) return raw as PinchConfig;
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Merge global (~/.pi/agent/pinch.json) and project (.pi/pinch.json)
 * manifests. Project entries override global ones by name.
 */
function readConfig(cwd: string): PinchConfig | null {
  const global = readManifest(globalManifestPath());
  const project = readManifest(projectManifestPath(cwd));
  if (!global && !project) return null;
  return { ...global, ...project };
}

function readLock(cwd: string): PinchLock {
  const p = lockPath(cwd);
  if (!fs.existsSync(p)) return {};
  try {
    return JSON.parse(fs.readFileSync(p, "utf-8")) as PinchLock;
  } catch {
    return {};
  }
}

function writeLock(cwd: string, lock: PinchLock): void {
  fs.mkdirSync(path.dirname(lockPath(cwd)), { recursive: true });
  fs.writeFileSync(lockPath(cwd), JSON.stringify(lock, null, 2) + "\n", "utf-8");
}

// ── Git operations ─────────────────────────────────────────────────────

function git(args: string[], opts?: { cwd?: string }): { ok: boolean; stdout: string; stderr: string } {
  try {
    const result = child_process.execFileSync("git", args, {
      cwd: opts?.cwd,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 60_000,
    });
    return { ok: true, stdout: result.trim(), stderr: "" };
  } catch (e: any) {
    return {
      ok: false,
      stdout: (e.stdout ?? "").toString().trim(),
      stderr: (e.stderr ?? "").toString().trim(),
    };
  }
}

function cloneOrFetch(name: string, repo: string, cwd: string): { ok: boolean; error?: string } {
  const dir = repoDir(cwd, name);

  if (fs.existsSync(path.join(dir, ".git"))) {
    const result = git(["fetch", "--all", "--prune"], { cwd: dir });
    if (!result.ok) return { ok: false, error: `fetch failed: ${result.stderr}` };
    return { ok: true };
  }

  fs.mkdirSync(path.dirname(dir), { recursive: true });
  const result = git(["clone", "--depth", "1", "--no-single-branch", repo, dir]);
  if (!result.ok) return { ok: false, error: `clone failed: ${result.stderr}` };
  return { ok: true };
}

function checkout(name: string, ref: string, cwd: string): { ok: boolean; commit?: string; error?: string } {
  const dir = repoDir(cwd, name);

  let target = ref;
  const originRef = git(["rev-parse", "--verify", `origin/${ref}`], { cwd: dir });
  if (originRef.ok) {
    target = `origin/${ref}`;
  }

  const result = git(["checkout", "--detach", target], { cwd: dir });
  if (!result.ok) return { ok: false, error: `checkout ${ref} failed: ${result.stderr}` };

  const rev = git(["rev-parse", "HEAD"], { cwd: dir });
  return { ok: true, commit: rev.stdout };
}

function getCurrentCommit(name: string, cwd: string): string | undefined {
  const dir = repoDir(cwd, name);
  const rev = git(["rev-parse", "HEAD"], { cwd: dir });
  return rev.ok ? rev.stdout : undefined;
}

// ── Cleanup ────────────────────────────────────────────────────────────

/**
 * Remove source dirs under .pi/pinch/ that are no longer in the config.
 */
function pruneStale(config: PinchConfig, cwd: string): string[] {
  const dir = pinchDir(cwd);
  if (!fs.existsSync(dir)) return [];

  const pruned: string[] = [];
  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry);
    try {
      if (!fs.statSync(full).isDirectory()) continue;
    } catch {
      continue;
    }

    if (!config[entry]) {
      fs.rmSync(full, { recursive: true, force: true });
      pruned.push(entry);
    }
  }

  return pruned;
}

// ── Skill discovery ────────────────────────────────────────────────────

/**
 * Resolve the base directory for a source's plugins.
 * If `path` is set (e.g. "plugins"), plugins are under <repo>/<path>/<plugin>/.
 * Otherwise plugins are at the repo root: <repo>/<plugin>/.
 */
function pluginBaseDir(cwd: string, name: string, source: PinchSource): string {
  const dir = repoDir(cwd, name);
  return source.path ? path.join(dir, source.path) : dir;
}

/**
 * Find all SKILL.md files inside a plugin's skills/ directory.
 */
function findPluginSkills(pluginDir: string): string[] {
  const skillsDir = path.join(pluginDir, "skills");
  if (!fs.existsSync(skillsDir)) return [];

  const paths: string[] = [];
  for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillMd = path.join(skillsDir, entry.name, "SKILL.md");
    if (fs.existsSync(skillMd)) {
      paths.push(skillMd);
    }
  }
  return paths;
}

/**
 * Collect all skill paths from installed plugins.
 */
function resolveSkillPaths(config: PinchConfig, cwd: string): string[] {
  const paths: string[] = [];

  for (const [name, source] of Object.entries(config)) {
    const base = pluginBaseDir(cwd, name, source);
    if (!fs.existsSync(base)) continue;

    for (const plugin of source.plugins) {
      paths.push(...findPluginSkills(path.join(base, plugin)));
    }
  }

  return paths;
}

// ── Install / Update logic ─────────────────────────────────────────────

interface SyncResult {
  installed: string[];
  updated: string[];
  pruned: string[];
  skills: string[];
  errors: string[];
}

function installAll(cwd: string, update: boolean): SyncResult {
  const config = readConfig(cwd);
  if (!config) return { installed: [], updated: [], pruned: [], errors: ['No pinch.json manifest found'], skills: [] };

  const lock = readLock(cwd);
  const newLock: PinchLock = {};
  const result: SyncResult = { installed: [], updated: [], pruned: [], errors: [], skills: [] };

  for (const [name, source] of Object.entries(config)) {
    const repoExists = fs.existsSync(path.join(repoDir(cwd, name), ".git"));
    const lockedCommit = lock[name]?.commit;
    const ref = source.ref ?? "HEAD";
    const isPinned = !!source.ref;

    if (!repoExists) {
      const clone = cloneOrFetch(name, source.repo, cwd);
      if (!clone.ok) {
        result.errors.push(`${name}: ${clone.error}`);
        continue;
      }
      result.installed.push(name);
    } else if (update) {
      const fetch = cloneOrFetch(name, source.repo, cwd);
      if (!fetch.ok) {
        result.errors.push(`${name}: ${fetch.error}`);
        if (lockedCommit) {
          newLock[name] = { commit: lockedCommit, ...(source.ref ? { ref: source.ref } : {}) };
        }
        continue;
      }
    }

    let targetRef = ref;
    if (!update && lockedCommit && repoExists) {
      targetRef = lockedCommit;
    } else if (update && isPinned) {
      targetRef = ref;
    } else if (update) {
      targetRef = "HEAD";
    }

    const co = checkout(name, targetRef, cwd);
    if (!co.ok) {
      result.errors.push(`${name}: ${co.error}`);
      continue;
    }

    const commit = co.commit ?? getCurrentCommit(name, cwd) ?? "unknown";

    if (update && lockedCommit && lockedCommit !== commit) {
      result.updated.push(name);
    }

    newLock[name] = { commit, ...(source.ref ? { ref: source.ref } : {}) };

    // Check plugins and their skills
    const base = pluginBaseDir(cwd, name, source);
    for (const plugin of source.plugins) {
      const pluginDir = path.join(base, plugin);
      if (!fs.existsSync(pluginDir)) {
        result.errors.push(`${name}: plugin "${plugin}" not found`);
        continue;
      }
      const skills = findPluginSkills(pluginDir);
      if (skills.length === 0) {
        result.errors.push(`${name}: plugin "${plugin}" has no skills`);
      }
      result.skills.push(...skills.map((s) => {
        const rel = path.relative(pinchDir(cwd), s);
        return rel.replace(/\/SKILL\.md$/, "");
      }));
    }
  }

  writeLock(cwd, newLock);
  result.pruned = pruneStale(config, cwd);

  return result;
}

// ── Extension ──────────────────────────────────────────────────────────

export default function pinch(pi: ExtensionAPI) {
  let cwd = "";

  pi.on("resources_discover", (event) => {
    cwd = event.cwd;
    const config = readConfig(cwd);
    if (!config) return;

    const skillPaths = resolveSkillPaths(config, cwd);
    if (skillPaths.length > 0) {
      return { skillPaths };
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    const config = readConfig(cwd);
    if (!config) return;

    const skillPaths = resolveSkillPaths(config, cwd);
    const totalPlugins = Object.values(config).reduce((n, s) => n + s.plugins.length, 0);
    const installedPlugins = Object.entries(config).reduce((n, [name, source]) => {
      const base = pluginBaseDir(cwd, name, source);
      return n + source.plugins.filter((p) => fs.existsSync(path.join(base, p))).length;
    }, 0);
    const missing = totalPlugins - installedPlugins;

    if (missing > 0) {
      ctx.ui.notify(
        `pinch: ${missing} plugin(s) not installed — run /pinch:install`,
        "warning"
      );
    } else if (skillPaths.length > 0) {
      ctx.ui.notify(`pinch: ${skillPaths.length} skill(s) from ${installedPlugins} plugin(s)`, "info");
    }
  });

  pi.registerCommand("pinch:install", {
    description: "Install plugins declared in pinch config",
    handler: async (_args, ctx) => {
      const config = readConfig(cwd);
      if (!config) {
        ctx.ui.notify('No pinch.json manifest found', "error");
        return;
      }

      ctx.ui.notify("pinch: installing...", "info");
      const result = installAll(cwd, false);
      reportResult(result, ctx);

      if (result.skills.length > 0) {
        await ctx.reload();
      }
    },
  });

  pi.registerCommand("pinch:update", {
    description: "Update plugins to latest (respects pinned refs)",
    handler: async (_args, ctx) => {
      const config = readConfig(cwd);
      if (!config) {
        ctx.ui.notify('No pinch.json manifest found', "error");
        return;
      }

      ctx.ui.notify("pinch: updating...", "info");
      const result = installAll(cwd, true);
      reportResult(result, ctx);

      if (result.updated.length > 0 || result.installed.length > 0) {
        await ctx.reload();
      }
    },
  });

  pi.registerCommand("pinch:status", {
    description: "Show installed plugins and their skills",
    handler: async (_args, ctx) => {
      const config = readConfig(cwd);
      if (!config) {
        ctx.ui.notify('No pinch.json manifest found', "error");
        return;
      }

      const lock = readLock(cwd);
      const lines: string[] = [];

      for (const [name, source] of Object.entries(config)) {
        const lockEntry = lock[name];
        const installed = fs.existsSync(path.join(repoDir(cwd, name), ".git"));
        const status = installed ? "✓" : "✗";
        const commit = lockEntry?.commit?.slice(0, 8) ?? "—";
        const ref = source.ref ?? "HEAD";

        lines.push(`${status} ${name} (${ref} @ ${commit})`);

        const base = pluginBaseDir(cwd, name, source);
        for (const plugin of source.plugins) {
          const pluginDir = path.join(base, plugin);
          const exists = fs.existsSync(pluginDir);
          const skills = exists ? findPluginSkills(pluginDir) : [];
          const skillNames = skills.map((s) => path.basename(path.dirname(s)));

          if (skills.length > 0) {
            lines.push(`  • ${plugin} (${skillNames.join(", ")})`);
          } else {
            lines.push(`  ? ${plugin}`);
          }
        }
      }

      await ctx.ui.select("Pinch Status", lines);
    },
  });
}

function reportResult(result: SyncResult, ctx: ExtensionContext): void {
  for (const err of result.errors) {
    ctx.ui.notify(`pinch: ${err}`, "error");
  }

  const parts: string[] = [];
  if (result.installed.length > 0) parts.push(`installed ${result.installed.length}`);
  if (result.updated.length > 0) parts.push(`updated ${result.updated.length}`);
  if (result.pruned.length > 0) parts.push(`pruned ${result.pruned.join(", ")}`);
  if (result.skills.length > 0) parts.push(`${result.skills.length} skill(s)`);

  if (parts.length > 0) {
    ctx.ui.notify(`pinch: ${parts.join(", ")}`, "info");
  }
}
