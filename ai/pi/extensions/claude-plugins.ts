/**
 * Claude Plugins Bridge
 *
 * Loads skills from Claude Code's plugin cache (~/.claude/plugins/cache)
 * and makes them available in pi. When a skill is also provided by pi itself
 * (skills/ directories or packages), the pi version wins and the Claude
 * plugin copy is skipped so the prompt never carries duplicates.
 *
 * Structure expected:
 *   ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/
 *     .claude-plugin/plugin.json
 *     skills/<skill-name>/SKILL.md
 *
 * When multiple versions of a plugin exist, the highest version is used.
 * Skills under examples/ directories are skipped.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CACHE_DIR = path.join(os.homedir(), ".claude", "plugins", "cache");

interface PluginSkill {
  name: string;
  description: string;
  path: string; // absolute path to SKILL.md
  plugin: string; // plugin name from plugin.json
}

/**
 * Compare version strings. Handles semver (1.2.3) and commit hashes
 * (hex strings treated as equal — we pick the first found).
 */
function compareVersions(a: string, b: string): number {
  const semverRe = /^(\d+)\.(\d+)\.(\d+)/;
  const ma = a.match(semverRe);
  const mb = b.match(semverRe);

  if (ma && mb) {
    for (let i = 1; i <= 3; i++) {
      const diff = parseInt(ma[i]) - parseInt(mb[i]);
      if (diff !== 0) return diff;
    }
    return 0;
  }

  // Non-semver (commit hashes, etc.) — no meaningful ordering
  return 0;
}

/**
 * Parse YAML-style frontmatter from a SKILL.md file.
 */
function parseFrontmatter(content: string): Record<string, string> {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) return {};

  const result: Record<string, string> = {};
  for (const line of match[1].split("\n")) {
    const kv = line.match(/^(\w[\w-]*):\s*(.+)/);
    if (kv) {
      result[kv[1]] = kv[2].trim();
    }
  }
  return result;
}

/**
 * Discover skills from the Claude plugins cache.
 */
function discoverSkills(): PluginSkill[] {
  if (!fs.existsSync(CACHE_DIR)) return [];

  // Collect: marketplace -> plugin -> version[]
  const plugins = new Map<string, { versions: string[]; marketplace: string; plugin: string }>();

  for (const marketplace of safeReaddir(CACHE_DIR)) {
    const marketDir = path.join(CACHE_DIR, marketplace);
    if (!isDir(marketDir)) continue;

    for (const plugin of safeReaddir(marketDir)) {
      const pluginDir = path.join(marketDir, plugin);
      if (!isDir(pluginDir)) continue;

      const key = `${marketplace}/${plugin}`;
      const entry = plugins.get(key) ?? { versions: [], marketplace, plugin };

      for (const version of safeReaddir(pluginDir)) {
        const versionDir = path.join(pluginDir, version);
        if (!isDir(versionDir)) continue;

        // Must have .claude-plugin/plugin.json to be a real plugin
        const pluginJson = path.join(versionDir, ".claude-plugin", "plugin.json");
        if (fs.existsSync(pluginJson)) {
          entry.versions.push(version);
        }
      }

      if (entry.versions.length > 0) {
        plugins.set(key, entry);
      }
    }
  }

  // For each plugin, pick the latest version and collect skills
  const skills: PluginSkill[] = [];

  for (const [key, { versions, marketplace, plugin }] of plugins) {
    const latest = versions.sort(compareVersions).at(-1)!;
    const versionDir = path.join(CACHE_DIR, marketplace, plugin, latest);

    // Read plugin name from plugin.json
    let pluginName = plugin;
    try {
      const meta = JSON.parse(
        fs.readFileSync(path.join(versionDir, ".claude-plugin", "plugin.json"), "utf-8")
      );
      if (meta.name) pluginName = meta.name;
    } catch {}

    // Find SKILL.md files under skills/ (not under examples/)
    const skillsDir = path.join(versionDir, "skills");
    if (!isDir(skillsDir)) continue;

    for (const skillFile of findSkillFiles(skillsDir, versionDir)) {
      try {
        const content = fs.readFileSync(skillFile, "utf-8");
        const fm = parseFrontmatter(content);
        if (!fm.description) continue; // pi requires a description

        const name = fm.name ?? path.basename(path.dirname(skillFile));
        skills.push({ name, description: fm.description, path: skillFile, plugin: pluginName });
      } catch {}
    }
  }

  return skills;
}

/**
 * Recursively find SKILL.md files, skipping examples/ directories.
 */
function findSkillFiles(dir: string, root: string): string[] {
  const results: string[] = [];

  for (const entry of safeReaddirEntries(dir)) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      // Skip examples directories relative to the plugin root
      const rel = path.relative(root, fullPath);
      if (rel.startsWith("examples")) continue;

      results.push(...findSkillFiles(fullPath, root));
    } else if (entry.name === "SKILL.md") {
      results.push(fullPath);
    }
  }

  return results;
}

function isDir(p: string): boolean {
  try {
    return fs.statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function safeReaddir(dir: string): string[] {
  try {
    return fs.readdirSync(dir);
  } catch {
    return [];
  }
}

function safeReaddirEntries(dir: string): fs.Dirent[] {
  try {
    return fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }
}

export default function claudePlugins(pi: ExtensionAPI) {
  // Raw skills discovered from the plugin cache this session.
  let discovered: PluginSkill[] = [];
  // Skills actually injected into the prompt, after deferring to pi's own.
  // Null until computed on the first before_agent_start of the session.
  let injected: PluginSkill[] | null = null;

  pi.on("session_start", async () => {
    discovered = discoverSkills();
    injected = null;
  });

  pi.on("before_agent_start", async (event, ctx) => {
    if (discovered.length === 0) return;

    // systemPromptOptions.skills is what pi already loaded from its own
    // skills/ directories and packages. Those win over plugin-cache copies.
    if (injected === null) {
      const piNames = new Set(
        (event.systemPromptOptions.skills ?? []).map((s) => s.name)
      );
      injected = discovered.filter((s) => !piNames.has(s.name));
      const skipped = discovered.length - injected.length;
      const msg =
        skipped > 0
          ? `Claude plugins: ${injected.length} skill(s) loaded, ${skipped} deferred to pi`
          : `Claude plugins: ${injected.length} skill(s) loaded`;
      ctx.ui.notify(msg, "info");
    }

    if (injected.length === 0) return;

    const xml = injected
      .map(
        (s) =>
          `  <skill>\n    <name>${s.name}</name>\n    <description>${escapeXml(s.description)}</description>\n    <location>${s.path}</location>\n  </skill>`
      )
      .join("\n");

    return {
      systemPrompt:
        event.systemPrompt +
        `\n\nThe following skills are available from Claude Code plugins.\nUse the read tool to load a skill's file when the task matches its description.\n\n<available_skills>\n${xml}\n</available_skills>\n`,
    };
  });
}

function escapeXml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&apos;");
}
