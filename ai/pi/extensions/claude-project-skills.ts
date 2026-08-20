/**
 * Claude Project Skills Bridge
 *
 * Loads project-local Claude Code skills (`.claude/skills/`) into pi.
 *
 * pi auto-discovers `.pi/skills` and `.agents/skills` from cwd up to the repo
 * root, but not `.claude/skills`. A relative `"skills"` entry in the global
 * settings.json cannot cover the gap either: global entries resolve against
 * `~/.pi/agent`, not the cwd, so `".claude/skills"` there points at a
 * directory that does not exist. This extension contributes the paths at
 * `resources_discover` time instead, so the skills register normally and get
 * their own `/skill:name` commands.
 *
 * Companion to claude-plugins.ts, which covers the plugin cache
 * (~/.claude/plugins/cache). User-level ~/.claude/skills is skipped here
 * because settings.json already loads ~/.dotfiles/ai/skills.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Directories from `startDir` up to the repo root, inclusive. Mirrors pi's own
 * ancestor walk for `.agents/skills`, and treats a jj repo without a colocated
 * git dir as a root too.
 */
function ancestorsToRepoRoot(startDir: string): string[] {
  const dirs: string[] = [];
  let dir = path.resolve(startDir);

  while (true) {
    dirs.push(dir);
    if (isRepoRoot(dir)) break;

    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  return dirs;
}

function isRepoRoot(dir: string): boolean {
  return fs.existsSync(path.join(dir, ".git")) || fs.existsSync(path.join(dir, ".jj"));
}

function isDir(p: string): boolean {
  try {
    return fs.statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function findSkillDirs(cwd: string): string[] {
  return ancestorsToRepoRoot(cwd)
    .map((dir) => path.join(dir, ".claude", "skills"))
    .filter(isDir);
}

export default function claudeProjectSkills(pi: ExtensionAPI) {
  pi.on("resources_discover", async (event, ctx) => {
    // `.claude/skills` is project-local content, so honor the same trust gate
    // pi applies to `.pi/` and `.agents/skills`.
    if (!ctx.isProjectTrusted()) return;

    const skillPaths = findSkillDirs(event.cwd);
    if (skillPaths.length === 0) return;

    return { skillPaths };
  });
}
