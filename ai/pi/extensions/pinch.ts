/**
 * Pinch — scoped plugin manager for pi
 *
 * Manages plugins from git repos declared in pinch.json manifests.
 * Two manifest locations define two scopes:
 *
 *   ~/.pi/agent/pinch.json   → user scope (applies everywhere)
 *   .pi/pinch.json           → project scope (per-repo)
 *
 * Scope determines where plugins are installed:
 *
 *   User scope    → ~/.pi/pinch/<source>/<plugin>/
 *   Project scope → .pi/pinch/<source>/<plugin>/
 *
 * A source belongs to project scope when it appears in the project
 * manifest (either as a new definition or referencing a global source).
 * Sources defined only in the global manifest stay in user scope,
 * keeping project directories free of user-specific plugins.
 *
 * Repos are cloned into $XDG_CACHE_HOME/pinch/<source>/ as a shared
 * cache. Only the requested plugins are copied into the scope directory.
 *
 * Plugin location within a repo is resolved by:
 * 1. Per-plugin `path` override in pinch.json (e.g. { "name": "foo", "path": "." })
 * 2. Source-level `path` field in pinch.json (e.g. "plugins")
 * 3. marketplace.json `source` field (e.g. "./plugins/playground")
 * 4. Repo root fallback (<repo>/<plugin>/)
 *
 * Lock files track exact commits per source, one per scope:
 *
 *   ~/.pi/agent/pinch-lock.json   → user scope
 *   .pi/pinch-lock.json           → project scope
 *
 * Commands:
 *   /pinch:install  — clone/fetch all sources, copy plugins, register skills
 *   /pinch:update   — pull latest for unpinned sources, re-copy plugins
 *   /pinch:status   — show installed plugins and their skills
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import * as child_process from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

// ── Types ──────────────────────────────────────────────────────────────

type Scope = "user" | "project";

/** A plugin entry: either a name string or an object with name and path override. */
type PluginSpec = string | { name: string; path: string };

interface PinchSource {
  repo: string;
  ref?: string;
  path?: string; // subdirectory containing plugins (e.g. "plugins")
  plugins: PluginSpec[];
}

interface PinchConfig {
  [name: string]: PinchSource;
}

/** Config split by scope — user (global-only) vs project (referenced in project manifest). */
interface ScopedConfig {
  user: PinchConfig;
  project: PinchConfig;
  errors: string[];
}

interface PinchLockEntry {
  commit: string;
  ref?: string; // informational — records which ref produced this commit
}

interface PinchLock {
  [name: string]: PinchLockEntry;
}

// ── Plugin spec helpers ─────────────────────────────────────────────────

function pluginName(spec: PluginSpec): string {
  return typeof spec === "string" ? spec : spec.name;
}

function pluginPathOverride(spec: PluginSpec): string | undefined {
  return typeof spec === "string" ? undefined : spec.path;
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

/** User-scoped plugin install dir (~/.pi/pinch/) */
function userPinchDir(): string {
  return path.join(os.homedir(), ".pi", "pinch");
}

/** Project-local plugin install dir */
function projectPinchDir(cwd: string): string {
  return path.join(cwd, ".pi", "pinch");
}

/** Root install dir for a given scope */
function pinchDir(scope: Scope, cwd: string): string {
  return scope === "user" ? userPinchDir() : projectPinchDir(cwd);
}

/** Installed plugin dir */
function installedPluginDir(scope: Scope, cwd: string, sourceName: string, pluginName: string): string {
  return path.join(pinchDir(scope, cwd), sourceName, pluginName);
}

function globalManifestPath(): string {
  return path.join(os.homedir(), ".pi", "agent", "pinch.json");
}

function projectManifestPath(cwd: string): string {
  return path.join(cwd, ".pi", "pinch.json");
}

function userLockPath(): string {
  return path.join(os.homedir(), ".pi", "agent", "pinch-lock.json");
}

function projectLockPath(cwd: string): string {
  return path.join(cwd, ".pi", "pinch-lock.json");
}

function lockPath(scope: Scope, cwd: string): string {
  return scope === "user" ? userLockPath() : projectLockPath(cwd);
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
 * Read and scope-split global (~/.pi/agent/pinch.json) and project
 * (.pi/pinch.json) manifests.
 *
 * Scope rules:
 * - A source that appears only in the global manifest → user scope.
 * - A source that appears in the project manifest (new or referencing
 *   a global source) → project scope.
 *
 * Global entries must have `repo` and `plugins`.
 * Project entries referencing a global key can only set `plugins` —
 * `repo`, `ref`, and `path` are disallowed (the global definition owns those).
 * Project entries with a new key are full source definitions (must have `repo`).
 *
 * Returns null if no valid config is found.
 */
function readConfig(cwd: string): ScopedConfig | null {
  const globalRaw = readJsonFile(globalManifestPath());
  const projectRaw = readJsonFile(projectManifestPath(cwd));
  if (!globalRaw && !projectRaw) return null;

  const globalSources: PinchConfig = {};
  const errors: string[] = [];

  // Parse global entries (must have repo)
  if (globalRaw) {
    for (const [name, entry] of Object.entries(globalRaw)) {
      if (typeof entry !== "object" || entry === null) continue;
      if (!("repo" in entry) || !("plugins" in entry)) continue;
      globalSources[name] = entry as PinchSource;
    }
  }

  const user: PinchConfig = {};
  const project: PinchConfig = {};
  const projectNames = new Set<string>();

  // Parse project entries, tracking which names the project claims
  if (projectRaw) {
    for (const [name, entry] of Object.entries(projectRaw)) {
      if (typeof entry !== "object" || entry === null) continue;
      if (!("plugins" in entry)) continue;
      projectNames.add(name);

      if (name in globalSources) {
        // Referencing a global source — only plugins allowed
        if ("repo" in entry || "ref" in entry || "path" in entry) {
          errors.push(`${name}: project manifest cannot override repo/ref/path of global source — only plugins allowed`);
          continue;
        }
        project[name] = { ...globalSources[name], plugins: (entry as PinchSource).plugins };
      } else {
        // New project-only source — full definition required
        if (!("repo" in entry)) {
          errors.push(`${name}: source must have repo`);
          continue;
        }
        project[name] = entry as PinchSource;
      }
    }
  }

  // Global sources not referenced by the project stay in user scope
  for (const [name, source] of Object.entries(globalSources)) {
    if (!projectNames.has(name)) {
      user[name] = source;
    }
  }

  const total = Object.keys(user).length + Object.keys(project).length;
  if (total === 0 && errors.length === 0) return null;
  return { user, project, errors };
}

/** Flat view of all sources across both scopes. */
function allSources(sc: ScopedConfig): PinchConfig {
  return { ...sc.user, ...sc.project };
}

/** Determine which scope a source belongs to. */
function sourceScope(sc: ScopedConfig, name: string): Scope {
  return name in sc.project ? "project" : "user";
}

function readLock(scope: Scope, cwd: string): PinchLock {
  const p = lockPath(scope, cwd);
  if (!fs.existsSync(p)) return {};
  try {
    return JSON.parse(fs.readFileSync(p, "utf-8")) as PinchLock;
  } catch {
    return {};
  }
}

function writeLock(scope: Scope, cwd: string, lock: PinchLock): void {
  const p = lockPath(scope, cwd);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(lock, null, 2) + "\n", "utf-8");
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
 * 1. Per-plugin `path` override from pinch.json plugin spec
 * 2. Source-level `path` in pinch.json → <cache>/<path>/<plugin>/
 * 3. marketplace.json `source` field → <cache>/<source>/
 * 4. Repo root fallback → <cache>/<plugin>/
 */
function cachedPluginDir(name: string, source: PinchSource, plugin: string, pathOverride?: string): string {
  const dir = cachedRepoDir(name);

  if (pathOverride) return path.join(dir, pathOverride);

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
 * Copy a plugin from the cache into the appropriate scope directory.
 * Removes the old copy first to ensure a clean state.
 */
function installPlugin(scope: Scope, cwd: string, sourceName: string, source: PinchSource, plugin: string, pathOverride?: string): { ok: boolean; error?: string } {
  const src = cachedPluginDir(sourceName, source, plugin, pathOverride);
  if (!fs.existsSync(src)) {
    return { ok: false, error: `plugin "${plugin}" not found in repo` };
  }

  const dest = installedPluginDir(scope, cwd, sourceName, plugin);
  fs.rmSync(dest, { recursive: true, force: true });
  copyDir(src, dest);
  return { ok: true };
}

// ── Cleanup ────────────────────────────────────────────────────────────

/**
 * Remove source/plugin dirs that are no longer in the config for a given scope.
 * Cleans up empty source directories after pruning individual plugins.
 */
function pruneScopeDir(scopeConfig: PinchConfig, dir: string): string[] {
  if (!fs.existsSync(dir)) return [];

  const pruned: string[] = [];

  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry);
    try {
      if (!fs.statSync(full).isDirectory()) continue;
    } catch {
      continue;
    }

    if (!scopeConfig[entry]) {
      // Entire source removed from this scope
      fs.rmSync(full, { recursive: true, force: true });
      pruned.push(entry);
    } else {
      // Prune plugins no longer in the list
      const wantedPlugins = new Set(scopeConfig[entry].plugins.map(pluginName));
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

/** Prune stale entries from both user and project scope directories. */
function pruneStale(sc: ScopedConfig, cwd: string): string[] {
  const pruned: string[] = [];
  pruned.push(...pruneScopeDir(sc.user, userPinchDir()));
  pruned.push(...pruneScopeDir(sc.project, projectPinchDir(cwd)));
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
 * Collect all skill paths from installed plugins across both scopes.
 */
function resolveSkillPaths(sc: ScopedConfig, cwd: string): string[] {
  const paths: string[] = [];

  for (const scope of ["user", "project"] as Scope[]) {
    const config = scope === "user" ? sc.user : sc.project;
    for (const [name, source] of Object.entries(config)) {
      for (const spec of source.plugins) {
        const dir = installedPluginDir(scope, cwd, name, pluginName(spec));
        if (fs.existsSync(dir)) {
          paths.push(...findPluginSkills(dir));
        }
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
  const sc = readConfig(cwd);
  if (!sc) return { installed: [], updated: [], copied: [], pruned: [], errors: ['No pinch.json manifest found'], skills: [] };

  const result: SyncResult = { installed: [], updated: [], copied: [], pruned: [], errors: [...sc.errors], skills: [] };

  // Process each scope independently (separate lock files)
  for (const scope of ["user", "project"] as Scope[]) {
    const config = scope === "user" ? sc.user : sc.project;
    if (Object.keys(config).length === 0) continue;

    const lock = readLock(scope, cwd);
    const newLock: PinchLock = {};

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

      // Copy plugins into the scope-appropriate directory
      for (const spec of source.plugins) {
        const plugin = pluginName(spec);
        const override = pluginPathOverride(spec);
        log(`copying ${name}/${plugin} (${scope})...`);
        const install = installPlugin(scope, cwd, name, source, plugin, override);
        if (!install.ok) {
          result.errors.push(`${name}: ${install.error}`);
          continue;
        }
        result.copied.push(`${name}/${plugin}`);
        const dest = installedPluginDir(scope, cwd, name, plugin);
        const skills = findPluginSkills(dest);
        result.skills.push(...skills.map((s) => {
          const base = pinchDir(scope, cwd);
          const rel = path.relative(base, s);
          return rel.replace(/\/SKILL\.md$/, "");
        }));
      }
    }

    writeLock(scope, cwd, newLock);
  }

  result.pruned = pruneStale(sc, cwd);

  return result;
}

// ── Extension ──────────────────────────────────────────────────────────

export default function pinch(pi: ExtensionAPI) {
  let cwd = "";

  pi.on("resources_discover", (event) => {
    cwd = event.cwd;
    const sc = readConfig(cwd);
    if (!sc) return;

    const skillPaths = resolveSkillPaths(sc, cwd);
    if (skillPaths.length > 0) {
      return { skillPaths };
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    const sc = readConfig(cwd);
    if (!sc) return;

    for (const err of sc.errors) {
      ctx.ui.notify(`pinch: ${err}`, "error");
    }

    const config = allSources(sc);
    const skillPaths = resolveSkillPaths(sc, cwd);
    const totalPlugins = Object.values(config).reduce((n, s) => n + s.plugins.length, 0);
    const installedPlugins = Object.entries(config).reduce((n, [name, source]) => {
      const scope = sourceScope(sc, name);
      return n + source.plugins.filter((spec) => fs.existsSync(installedPluginDir(scope, cwd, name, pluginName(spec)))).length;
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
      const sc = readConfig(cwd);
      if (!sc) {
        ctx.ui.notify('No pinch.json manifest found', "error");
        return;
      }

      for (const err of sc.errors) {
        ctx.ui.notify(`pinch: ${err}`, "error");
      }

      const lines: string[] = [];

      for (const scope of ["user", "project"] as Scope[]) {
        const config = scope === "user" ? sc.user : sc.project;
        if (Object.keys(config).length === 0) continue;

        const lock = readLock(scope, cwd);
        lines.push(`── ${scope} ──`);

        for (const [name, source] of Object.entries(config)) {
          const lockEntry = lock[name];
          const cached = fs.existsSync(path.join(cachedRepoDir(name), ".git"));
          const status = cached ? "✓" : "✗";
          const commit = lockEntry?.commit?.slice(0, 8) ?? "—";
          const ref = source.ref ?? "HEAD";

          lines.push(`${status} ${name} (${ref} @ ${commit})`);

          for (const spec of source.plugins) {
            const plugin = pluginName(spec);
            const pDir = installedPluginDir(scope, cwd, name, plugin);
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
