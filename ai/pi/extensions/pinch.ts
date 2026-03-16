/**
 * Pinch — per-project plugin manager for pi
 *
 * Manages Claude plugins from git repos declared in pinch.json manifests.
 * Global manifest: ~/.pi/agent/pinch.json
 * Project manifest: .pi/pinch.json (overrides global by name)
 *
 * Repos are cloned into $XDG_CACHE_HOME/pinch/<source>/ as a shared cache.
 * Only the requested plugins are copied into the project at
 * .pi/pinch/<source>/<plugin>/. This keeps projects lightweight and works
 * in bind-mounted containers (no symlinks pointing outside the mount).
 *
 * Plugin location within a repo is resolved by:
 * 1. Explicit `path` field in pinch.json (e.g. "plugins")
 * 2. marketplace.json `source` field (e.g. "./plugins/playground")
 * 3. Repo root fallback (<repo>/<plugin>/)
 *
 * Manifest format (pinch.json):
 *
 *   {
 *     "anthropic": {
 *       "repo": "https://github.com/anthropics/claude-plugins-official",
 *       "ref": "main",
 *       "plugins": ["playground", "skill-creator"]
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
 *   /pinch:install  — clone/fetch all sources, copy plugins, register skills
 *   /pinch:update   — pull latest for unpinned sources, re-copy plugins
 *   /pinch:status   — show installed plugins and their skills
 *
 * Lock file (.pi/pinch-lock.json) tracks exact commits per source.
 * The `ref` field in lock entries is informational only — checkout uses
 * the commit hash directly for reproducibility.
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
  ref?: string; // informational — records which ref produced this commit
}

interface PinchLock {
  [name: string]: PinchLockEntry;
}

// ── Container detection ────────────────────────────────────────────────

function inContainer(): boolean {
  return fs.existsSync("/.dockerenv") || fs.existsSync("/run/.containerenv");
}

// ── Paths ──────────────────────────────────────────────────────────────

/** XDG cache dir for repo clones */
function cacheDir(): string {
  const xdg = process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache");
  return path.join(xdg, "pinch");
}

/** Cached repo clone for a source */
function cachedRepoDir(name: string): string {
  return path.join(cacheDir(), name);
}

/** Project-local plugin install dir */
function projectPinchDir(cwd: string): string {
  return path.join(cwd, ".pi", "pinch");
}

/** Installed plugin dir within the project */
function installedPluginDir(cwd: string, sourceName: string, pluginName: string): string {
  return path.join(projectPinchDir(cwd), sourceName, pluginName);
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

function readJsonFile(filePath: string): Record<string, any> | null {
  if (!fs.existsSync(filePath)) return null;
  try {
    const raw = JSON.parse(fs.readFileSync(filePath, "utf-8"));
    if (!raw || typeof raw !== "object") return null;
    return raw;
  } catch {
    return null;
  }
}

/**
 * Merge global (~/.pi/agent/pinch.json) and project (.pi/pinch.json)
 * manifests.
 *
 * - Global entries must have `repo` and `plugins`.
 * - Project entries referencing a global key can only set `plugins` —
 *   `repo`, `ref`, and `path` are disallowed (the global definition owns those).
 * - Project entries with a new key are full source definitions (must have `repo`).
 *
 * Returns null if no valid config is found.
 */
interface ConfigResult {
  config: PinchConfig;
  errors: string[];
}

function readConfig(cwd: string): ConfigResult | null {
  const globalRaw = readJsonFile(globalManifestPath());
  const projectRaw = readJsonFile(projectManifestPath(cwd));
  if (!globalRaw && !projectRaw) return null;

  const config: PinchConfig = {};
  const errors: string[] = [];

  // Load global entries (must have repo)
  if (globalRaw) {
    for (const [name, entry] of Object.entries(globalRaw)) {
      if (typeof entry !== "object" || entry === null) continue;
      if (!("repo" in entry) || !("plugins" in entry)) continue;
      config[name] = entry as PinchSource;
    }
  }

  // Merge project entries
  if (projectRaw) {
    for (const [name, entry] of Object.entries(projectRaw)) {
      if (typeof entry !== "object" || entry === null) continue;
      if (!("plugins" in entry)) continue;

      if (name in config) {
        // Referencing a global source — only plugins allowed
        if ("repo" in entry || "ref" in entry || "path" in entry) {
          errors.push(`${name}: project manifest cannot override repo/ref/path of global source — only plugins allowed`);
          continue;
        }
        config[name] = { ...config[name], plugins: (entry as PinchSource).plugins };
      } else {
        // New project-only source — full definition required
        if (!("repo" in entry)) {
          errors.push(`${name}: source must have repo`);
          continue;
        }
        config[name] = entry as PinchSource;
      }
    }
  }

  if (Object.keys(config).length === 0 && errors.length === 0) return null;
  return { config, errors };
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
      timeout: 120_000,
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

function cloneOrFetch(name: string, repo: string): { ok: boolean; error?: string } {
  const dir = cachedRepoDir(name);

  if (fs.existsSync(path.join(dir, ".git"))) {
    const result = git(["fetch", "--all", "--prune"], { cwd: dir });
    if (!result.ok) return { ok: false, error: `fetch failed: ${result.stderr}` };
    return { ok: true };
  }

  fs.mkdirSync(path.dirname(dir), { recursive: true });
  const result = git(["clone", repo, dir]);
  if (!result.ok) return { ok: false, error: `clone failed: ${result.stderr}` };
  return { ok: true };
}

function checkout(name: string, ref: string): { ok: boolean; commit?: string; error?: string } {
  const dir = cachedRepoDir(name);

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

function getCurrentCommit(name: string): string | undefined {
  const dir = cachedRepoDir(name);
  const rev = git(["rev-parse", "HEAD"], { cwd: dir });
  return rev.ok ? rev.stdout : undefined;
}

// ── Marketplace ────────────────────────────────────────────────────────

interface MarketplaceEntry {
  name: string;
  source: string | { source: string; url?: string; path?: string };
  [key: string]: any;
}

interface Marketplace {
  plugins?: MarketplaceEntry[];
  [key: string]: any;
}

/** Per-source cache of marketplace plugin name → source path */
const marketplaceCache = new Map<string, Map<string, string> | null>();

/**
 * Read .claude-plugin/marketplace.json from a repo.
 * Returns a cached map of plugin name → relative source path.
 */
function readMarketplace(dir: string): Map<string, string> | null {
  if (marketplaceCache.has(dir)) return marketplaceCache.get(dir)!;

  const mp = path.join(dir, ".claude-plugin", "marketplace.json");
  if (!fs.existsSync(mp)) {
    marketplaceCache.set(dir, null);
    return null;
  }

  try {
    const data = JSON.parse(fs.readFileSync(mp, "utf-8")) as Marketplace;
    if (!data.plugins) {
      marketplaceCache.set(dir, null);
      return null;
    }

    const map = new Map<string, string>();
    for (const entry of data.plugins) {
      if (typeof entry.source === "string") {
        map.set(entry.name, entry.source);
      }
    }
    const result = map.size > 0 ? map : null;
    marketplaceCache.set(dir, result);
    return result;
  } catch {
    marketplaceCache.set(dir, null);
    return null;
  }
}

/** Clear the marketplace cache (call after checkout changes the working tree) */
function clearMarketplaceCache(): void {
  marketplaceCache.clear();
}

// ── Plugin resolution ──────────────────────────────────────────────────

/**
 * Resolve the source directory of a plugin within the cached repo.
 *
 * Resolution order:
 * 1. Explicit `path` in pinch.json → <cache>/<path>/<plugin>/
 * 2. marketplace.json `source` field → <cache>/<source>/
 * 3. Repo root fallback → <cache>/<plugin>/
 */
function cachedPluginDir(name: string, source: PinchSource, plugin: string): string {
  const dir = cachedRepoDir(name);

  if (source.path) return path.join(dir, source.path, plugin);

  const marketplace = readMarketplace(dir);
  if (marketplace) {
    const sourcePath = marketplace.get(plugin);
    if (sourcePath) return path.join(dir, sourcePath);
  }

  return path.join(dir, plugin);
}

// ── Copy plugins ───────────────────────────────────────────────────────

/** Recursively copy a directory, creating parents as needed. Skips symlinks. */
function copyDir(src: string, dest: string): void {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isSymbolicLink()) {
      continue; // skip symlinks — they may point outside the repo
    } else if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else if (entry.isFile()) {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

/**
 * Copy a plugin from the cache into the project.
 * Removes the old copy first to ensure a clean state.
 */
function installPlugin(cwd: string, sourceName: string, source: PinchSource, plugin: string): { ok: boolean; error?: string } {
  const src = cachedPluginDir(sourceName, source, plugin);
  if (!fs.existsSync(src)) {
    return { ok: false, error: `plugin "${plugin}" not found in repo` };
  }

  const dest = installedPluginDir(cwd, sourceName, plugin);
  fs.rmSync(dest, { recursive: true, force: true });
  copyDir(src, dest);
  return { ok: true };
}

// ── Cleanup ────────────────────────────────────────────────────────────

/**
 * Remove source/plugin dirs under .pi/pinch/ that are no longer in the config.
 * Cleans up empty source directories after pruning individual plugins.
 */
function pruneStale(config: PinchConfig, cwd: string): string[] {
  const dir = projectPinchDir(cwd);
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
      // Entire source removed
      fs.rmSync(full, { recursive: true, force: true });
      pruned.push(entry);
    } else {
      // Prune plugins no longer in the list
      const wantedPlugins = new Set(config[entry].plugins);
      for (const pluginEntry of fs.readdirSync(full)) {
        const pluginFull = path.join(full, pluginEntry);
        try {
          if (!fs.statSync(pluginFull).isDirectory()) continue;
        } catch {
          continue;
        }
        if (!wantedPlugins.has(pluginEntry)) {
          fs.rmSync(pluginFull, { recursive: true, force: true });
          pruned.push(`${entry}/${pluginEntry}`);
        }
      }

      // Remove empty source directory
      try {
        const remaining = fs.readdirSync(full);
        if (remaining.length === 0) {
          fs.rmdirSync(full);
        }
      } catch {}
    }
  }

  return pruned;
}

// ── Skill discovery ────────────────────────────────────────────────────

/**
 * Find all SKILL.md files inside a plugin's skills/ directory.
 */
function findPluginSkills(dir: string): string[] {
  const skillsDir = path.join(dir, "skills");
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
 * Collect all skill paths from installed plugins (project copies).
 */
function resolveSkillPaths(config: PinchConfig, cwd: string): string[] {
  const paths: string[] = [];

  for (const [name, source] of Object.entries(config)) {
    for (const plugin of source.plugins) {
      const dir = installedPluginDir(cwd, name, plugin);
      if (fs.existsSync(dir)) {
        paths.push(...findPluginSkills(dir));
      }
    }
  }

  return paths;
}

// ── Install / Update logic ─────────────────────────────────────────────

interface SyncResult {
  installed: string[];
  updated: string[];
  copied: string[];
  pruned: string[];
  skills: string[];
  errors: string[];
}

type Log = (msg: string) => void;

function installAll(cwd: string, update: boolean, log: Log): SyncResult {
  const cr = readConfig(cwd);
  if (!cr) return { installed: [], updated: [], copied: [], pruned: [], errors: ['No pinch.json manifest found'], skills: [] };

  const { config, errors: configErrors } = cr;
  const lock = readLock(cwd);
  const newLock: PinchLock = {};
  const result: SyncResult = { installed: [], updated: [], copied: [], pruned: [], errors: [...configErrors], skills: [] };

  for (const [name, source] of Object.entries(config)) {
    const repoExists = fs.existsSync(path.join(cachedRepoDir(name), ".git"));
    const lockedCommit = lock[name]?.commit;
    const ref = source.ref ?? "HEAD";
    const isPinned = !!source.ref;

    // Clone or fetch into cache
    if (!repoExists) {
      log(`cloning ${name} from ${source.repo}...`);
      const clone = cloneOrFetch(name, source.repo);
      if (!clone.ok) {
        result.errors.push(`${name}: ${clone.error}`);
        continue;
      }
      result.installed.push(name);
    } else if (update) {
      log(`fetching ${name}...`);
      const fetch = cloneOrFetch(name, source.repo);
      if (!fetch.ok) {
        result.errors.push(`${name}: ${fetch.error}`);
        if (lockedCommit) {
          newLock[name] = { commit: lockedCommit, ...(source.ref ? { ref: source.ref } : {}) };
        }
        continue;
      }
    }

    // Determine which ref to checkout
    let targetRef = ref;
    if (!update && lockedCommit && repoExists) {
      targetRef = lockedCommit;
    } else if (update && isPinned) {
      targetRef = ref;
    } else if (update) {
      targetRef = "HEAD";
    }

    log(`checking out ${name} at ${targetRef === ref ? ref : targetRef.slice(0, 8)}...`);
    clearMarketplaceCache();
    const co = checkout(name, targetRef);
    if (!co.ok) {
      result.errors.push(`${name}: ${co.error}`);
      continue;
    }

    const commit = co.commit ?? getCurrentCommit(name) ?? "unknown";

    if (update && lockedCommit && lockedCommit !== commit) {
      result.updated.push(name);
    }

    newLock[name] = { commit, ...(source.ref ? { ref: source.ref } : {}) };

    // Copy plugins from cache into project
    for (const plugin of source.plugins) {
      log(`copying ${name}/${plugin}...`);
      const install = installPlugin(cwd, name, source, plugin);
      if (!install.ok) {
        result.errors.push(`${name}: ${install.error}`);
        continue;
      }
      result.copied.push(`${name}/${plugin}`);
      const dest = installedPluginDir(cwd, name, plugin);
      const skills = findPluginSkills(dest);
      result.skills.push(...skills.map((s) => {
        const rel = path.relative(projectPinchDir(cwd), s);
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
    const cr = readConfig(cwd);
    if (!cr) return;

    const skillPaths = resolveSkillPaths(cr.config, cwd);
    if (skillPaths.length > 0) {
      return { skillPaths };
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    const cr = readConfig(cwd);
    if (!cr) return;

    for (const err of cr.errors) {
      ctx.ui.notify(`pinch: ${err}`, "error");
    }

    const { config } = cr;
    const skillPaths = resolveSkillPaths(config, cwd);
    const totalPlugins = Object.values(config).reduce((n, s) => n + s.plugins.length, 0);
    const installedPlugins = Object.entries(config).reduce((n, [name, source]) => {
      return n + source.plugins.filter((p) => fs.existsSync(installedPluginDir(cwd, name, p))).length;
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
      if (inContainer()) {
        ctx.ui.notify("pinch: cannot install inside a container — run on the host", "error");
        return;
      }
      const log = (msg: string) => ctx.ui.notify(`pinch: ${msg}`, "info");
      const result = installAll(cwd, false, log);
      reportResult(result, ctx);

      if (result.skills.length > 0 || result.pruned.length > 0) {
        await ctx.reload();
      }
    },
  });

  pi.registerCommand("pinch:update", {
    description: "Update plugins to latest (respects pinned refs)",
    handler: async (_args, ctx) => {
      if (inContainer()) {
        ctx.ui.notify("pinch: cannot update inside a container — run on the host", "error");
        return;
      }
      const log = (msg: string) => ctx.ui.notify(`pinch: ${msg}`, "info");
      const result = installAll(cwd, true, log);
      reportResult(result, ctx);

      if (result.updated.length > 0 || result.installed.length > 0 || result.pruned.length > 0) {
        await ctx.reload();
      }
    },
  });

  pi.registerCommand("pinch:status", {
    description: "Show installed plugins and their skills",
    handler: async (_args, ctx) => {
      const cr = readConfig(cwd);
      if (!cr) {
        ctx.ui.notify('No pinch.json manifest found', "error");
        return;
      }

      for (const err of cr.errors) {
        ctx.ui.notify(`pinch: ${err}`, "error");
      }

      const lock = readLock(cwd);
      const lines: string[] = [];

      for (const [name, source] of Object.entries(cr.config)) {
        const lockEntry = lock[name];
        const cached = fs.existsSync(path.join(cachedRepoDir(name), ".git"));
        const status = cached ? "✓" : "✗";
        const commit = lockEntry?.commit?.slice(0, 8) ?? "—";
        const ref = source.ref ?? "HEAD";

        lines.push(`${status} ${name} (${ref} @ ${commit})`);

        for (const plugin of source.plugins) {
          const pDir = installedPluginDir(cwd, name, plugin);
          const exists = fs.existsSync(pDir);
          const skills = exists ? findPluginSkills(pDir) : [];
          const skillNames = skills.map((s) => path.basename(path.dirname(s)));

          if (skills.length > 0) {
            lines.push(`  • ${plugin} (${skillNames.join(", ")})`);
          } else if (exists) {
            lines.push(`  • ${plugin}`);
          } else {
            lines.push(`  ✗ ${plugin} (not installed)`);
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
  if (result.installed.length > 0) parts.push(`cloned ${result.installed.join(", ")}`);
  if (result.updated.length > 0) parts.push(`updated ${result.updated.join(", ")}`);
  if (result.copied.length > 0) parts.push(`copied ${result.copied.length} plugin(s)`);
  if (result.pruned.length > 0) parts.push(`pruned ${result.pruned.join(", ")}`);
  if (result.skills.length > 0) parts.push(`${result.skills.length} skill(s)`);

  if (parts.length > 0) {
    ctx.ui.notify(`pinch: ${parts.join(", ")}`, "info");
  } else if (result.errors.length === 0) {
    ctx.ui.notify("pinch: nothing to do", "info");
  }
}
