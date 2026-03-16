---
name: pinch
description: Manage pi plugins from git repos via pinch — add/remove sources and plugins in pinch.json, install, update, and troubleshoot. Use when the user wants to add a plugin, configure a marketplace/source, or debug pinch issues.
---

# Pinch

Pinch is a per-project plugin manager for pi, implemented as a pi extension (`~/.pi/agent/extensions/pinch.ts`). It clones git repos containing plugins (with skills, etc.) into `.pi/pinch/` and registers their skills automatically.

## Concepts

- **Source**: A named git repo entry in `pinch.json`. Each source has a `repo` URL, optional `ref` (branch/tag/commit), optional `path` (subdirectory containing plugins), and a `plugins` array listing which plugins to activate.
- **Plugin**: A directory inside a source repo following Claude plugin conventions — contains `skills/<skill-name>/SKILL.md`.
- **Lock file**: `.pi/pinch-lock.json` tracks the exact commit per source for reproducible installs.

## Manifest format

Manifests are JSON files named `pinch.json`:

- **Global**: `~/.pi/agent/pinch.json` — applies to all projects
- **Project**: `.pi/pinch.json` — project-specific, overrides global entries by name

```json
{
  "source-name": {
    "repo": "https://github.com/owner/repo",
    "ref": "main",
    "path": "plugins",
    "plugins": ["plugin-a", "plugin-b"]
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `repo` | Yes | Git clone URL (HTTPS or SSH) |
| `ref` | No | Branch, tag, or commit. Omit for HEAD. Pinned refs are not updated by `/pinch:update`. |
| `path` | No | Subdirectory within the repo that contains the plugin directories. Auto-detected if omitted (scans one level deep for `.claude-plugin/plugin.json`). |
| `plugins` | Yes | Array of plugin directory names to activate from this source |

## Commands

| Command | Description |
|---------|-------------|
| `/pinch:install` | Clone sources and register skills. Respects lock file for already-installed sources. |
| `/pinch:update` | Fetch latest and update to newest commits. Pinned refs stay put. |
| `/pinch:status` | Show installed sources, plugins, and their skills. |

## Manifest rules

- **Global manifest** (`~/.pi/agent/pinch.json`): Full source definitions with `repo`, `ref`, `path`, `plugins`.
- **Project manifest** (`.pi/pinch.json`): Can define new sources (with `repo`), or reference global sources by name with only `plugins`. If a key exists in the global manifest, `repo`/`ref`/`path` cannot be overridden — only `plugins` is allowed.

```json
// Project manifest referencing a global source (plugins only)
{
  "claude-plugins-official": {
    "plugins": ["playground", "skill-creator"]
  }
}

// Project manifest with its own source (full definition, new key)
{
  "my-team-plugins": {
    "repo": "git@github.com:team/plugins.git",
    "ref": "main",
    "plugins": ["our-plugin"]
  }
}
```

## Adding a plugin

1. Identify the repo URL and which plugin(s) you want from it.
2. Choose a short source name (used as the directory name under `.pi/pinch/`).
3. Add the entry to the appropriate `pinch.json`:

```json
{
  "anthropic": {
    "repo": "https://github.com/anthropics/claude-plugins-official",
    "ref": "main",
    "plugins": ["playgrounds"]
  }
}
```

If the plugins live in a subdirectory of the repo (not at the root), set `path`:

```json
{
  "my-source": {
    "repo": "https://github.com/owner/repo",
    "ref": "main",
    "path": "plugins",
    "plugins": ["the-plugin"]
  }
}
```

4. Run `/pinch:install` to clone and activate.

## Removing a plugin

- To stop using a single plugin from a source, remove it from the `plugins` array.
- To remove an entire source, delete its key from `pinch.json`. The next `/pinch:install` prunes stale directories.

## File layout

```
$XDG_CACHE_HOME/pinch/         # Shared repo cache (~/.cache/pinch/)
└── <source-name>/             # Full repo clone

.pi/
├── pinch.json                  # Project manifest (optional)
├── pinch-lock.json             # Lock file (auto-generated)
└── pinch/
    └── <source-name>/
        └── <plugin>/           # Copied from cache (only selected plugins)
            └── skills/
                └── <skill>/
                    └── SKILL.md

~/.pi/agent/
├── pinch.json                  # Global manifest
└── extensions/
    └── pinch.ts                # The extension itself
```

Repos are cloned once into the XDG cache. Only the requested plugin directories are copied into the project, keeping `.pi/pinch/` lightweight and working correctly in bind-mounted containers.

## Troubleshooting

- **"No pinch.json manifest found"**: Neither `~/.pi/agent/pinch.json` nor `.pi/pinch.json` exists or contains valid entries.
- **Plugin not found after install**: Check that the plugin name in `plugins` matches the actual directory name in the repo. Use `path` if plugins are nested.
- **Network errors on clone/fetch**: Pinch uses `git` directly — check that the repo URL is reachable and credentials are configured.
- **Skills not loading**: Plugin must have `skills/<name>/SKILL.md` structure. Run `/pinch:status` to verify.
