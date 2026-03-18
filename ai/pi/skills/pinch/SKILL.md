---
name: pinch
description: Manage pi plugins from git repos via pinch — add/remove sources and plugins in pinch.json, install, update, and troubleshoot. Use when the user wants to add a plugin, configure a marketplace/source, or debug pinch issues.
---

# Pinch

Pinch is a scoped plugin manager for pi, implemented as a pi extension (`~/.pi/agent/extensions/pinch.ts`). It clones git repos containing plugins (with skills, etc.) and copies them into scope-appropriate directories.

## Scoping

Each source belongs to one of two scopes, determined by which manifests reference it:

- User scope — sources defined only in `~/.pi/agent/pinch.json`. Plugins install to `~/.pi/pinch/`. Lock file: `~/.pi/agent/pinch-lock.json`.
- Project scope — sources that appear in `.pi/pinch.json` (new definitions or references to global sources). Plugins install to `.pi/pinch/`. Lock file: `.pi/pinch-lock.json`.

This separation keeps user-specific plugins out of project repositories.

## Concepts

- Source: a named git repo entry in `pinch.json` with a `repo` URL, optional `ref` (branch/tag/commit), optional `path` (subdirectory containing plugins), and a `plugins` array.
- Plugin: a directory inside a source repo containing `skills/<skill-name>/SKILL.md`.
- Lock file: tracks the exact commit per source for reproducible installs. One lock file per scope.

## Manifest format

Manifests are JSON files named `pinch.json`:

- `~/.pi/agent/pinch.json` — global (user) manifest, applies everywhere
- `.pi/pinch.json` — project manifest, overrides global entries by name

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
| `/pinch:status` | Show installed sources, plugins, and their skills, grouped by scope. |

## Manifest rules

The global manifest (`~/.pi/agent/pinch.json`) holds full source definitions with `repo`, `ref`, `path`, and `plugins`.

The project manifest (`.pi/pinch.json`) can define new sources (with `repo`) or reference global sources by name with only `plugins`. When a key exists in the global manifest, `repo`/`ref`/`path` cannot be overridden — only `plugins` is allowed. Referencing a global source in the project manifest promotes it to project scope.

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
2. Choose a short source name (used as the directory name under the install location).
3. Add the entry to the appropriate `pinch.json` — global for user-wide plugins, project for repo-specific ones.

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

To stop using a single plugin from a source, remove it from the `plugins` array. To remove an entire source, delete its key from `pinch.json`. The next `/pinch:install` prunes stale directories.

## File layout

```
$XDG_CACHE_HOME/pinch/            # Shared repo cache (~/.cache/pinch/)
└── <source-name>/                # Full repo clone

~/.pi/
├── agent/
│   ├── pinch.json                 # Global manifest
│   ├── pinch-lock.json            # User-scope lock file
│   └── extensions/
│       └── pinch.ts               # The extension itself
└── pinch/                         # User-scope installs
    └── <source-name>/
        └── <plugin>/
            └── skills/
                └── <skill>/
                    └── SKILL.md

.pi/                               # Project scope
├── pinch.json                     # Project manifest (optional)
├── pinch-lock.json                # Project-scope lock file
└── pinch/
    └── <source-name>/
        └── <plugin>/
            └── skills/
                └── <skill>/
                    └── SKILL.md
```

Repos are cloned once into the XDG cache. Only the requested plugin directories are copied into the scope-appropriate install location.

## Troubleshooting

- "No pinch.json manifest found": neither `~/.pi/agent/pinch.json` nor `.pi/pinch.json` exists or contains valid entries.
- Plugin not found after install: check that the plugin name in `plugins` matches the actual directory name in the repo. Use `path` if plugins are nested.
- Network errors on clone/fetch: pinch uses `git` directly — check that the repo URL is reachable and credentials are configured.
- Skills not loading: the plugin must have `skills/<name>/SKILL.md` structure. Run `/pinch:status` to verify.
- Wrong scope: if a user plugin appears in the project, check whether the project manifest references that source name. Remove the reference to keep it in user scope.
