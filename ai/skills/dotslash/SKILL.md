---
name: dotslash
description: Use when adding, updating, or troubleshooting DotSlash binaries in bin/ — covers file creation, Rakefile integration, and the dotslash CLI helpers
---

# DotSlash Binaries

This repo uses [DotSlash](https://dotslash-cli.com) to manage binaries in `bin/`. DotSlash files are lightweight JSON wrappers that lazily fetch, verify, cache, and run executables. Only `macos-aarch64` platform entries are needed. Run `dotslash --help` for the full CLI; `create-url-entry` is the only subcommand these workflows use.

## Adding a new DotSlash binary

The `update_dotslash_release` helper in `Rakefile` generates the file for you — you rarely hand-write the JSON.

### 1. Add a Rake task

In the `dotslash` namespace, add a task that calls the helper, then list `<name>` in the `all` task. The helper resolves the latest tag with `gh release view`, runs `create-url-entry`, and writes `bin/<name>`:

```ruby
desc "Update ramekin"
task(:ramekin) do
  update_dotslash_release(name: "ramekin", repo: "kejadlen/ramekin") { "ramekin-aarch64-apple-darwin.tar.gz" }
end
```

The block receives the resolved tag and returns the asset filename. Ignore the tag when the name is fixed (as above), or interpolate it (e.g. `{ |tag| "jj-#{tag}-aarch64-apple-darwin.tar.gz" }`). Pass `path:` when the executable sits inside an archive subdirectory; it defaults to `name`, which is correct when the archive holds a single file at its root. When the subdirectory embeds the version (e.g. `cq-0.2.1-aarch64-apple-darwin/cq`), pass `path:` a proc — it receives the resolved tag just like the asset block, so the generated `path` stays correct across release bumps:

```ruby
desc "Update cq"
task(:cq) do
  update_dotslash_release(name: "cq", repo: "technicalpickles/cq", path: ->(tag) { "cq-#{tag.delete_prefix("v")}-aarch64-apple-darwin/cq" }) { |tag| "cq-#{tag.delete_prefix("v")}-aarch64-apple-darwin.tar.gz" }
end
```

### 2. Generate and verify

```bash
rake dotslash:<name>
chmod +x bin/<name>
bin/<name> --help   # or whatever smoke test is appropriate
```

### Hand-writing the file (fallback)

Prefer extending `update_dotslash_release` over hand-writing JSON. Reserve hand-writing for cases the helper structurally can't reach — a non-GitHub host or an unusual URL scheme:

1. Find the asset with `gh release view --repo owner/repo --json tagName,assets` and pick the `macos-arm64` / `macos-aarch64` / `darwin-arm64` one.
2. Run `dotslash -- create-url-entry URL`. It computes size and hash and infers `format` from the URL suffix; you fill in `path`.
3. Determine `path`: for a bare binary, the filename to save as (e.g. `"jq"`, omit `format`); for an archive, the executable's relative path inside it (list contents with `curl -sL URL | tar tzf -`).
4. Write `bin/<name>` with the structure below, then `chmod +x`:

```
#!/usr/bin/env dotslash

{
  "name": "<name>",
  "platforms": {
    "macos-aarch64": {
      "size": <size>,
      "hash": "blake3",
      "digest": "<digest>",
      "format": "<format>",          // omit for bare binaries
      "path": "<path>",
      "providers": [
        {
          "url": "<url>"
        },
        {
          "type": "github-release",
          "repo": "https://github.com/owner/repo",
          "tag": "<tag>",
          "name": "<asset-filename>"
        }
      ]
    }
  }
}
```

Include both an HTTP provider (direct URL, tried first) and a GitHub Release provider (uses `gh` CLI, works with private repos).

## Updating existing binaries

Run:

```bash
rake dotslash:all       # every binary
rake dotslash:<name>    # a single binary
```

## Key details

- Use `blake3` (preferred) or `sha256` for the hash. The `create-url-entry` helper defaults to blake3.
- The `format` field must be a recognized value: `tar.gz`, `tar.zst`, `tar.xz`, `tar.bz2`, `tar`, `zip`, `gz`, `zst`, `xz`, `bz2`. `tgz` is not valid; use `tar.gz`.
- The `path` must be a normalized relative UNIX path: no leading `./`, no `..`, no trailing `/`, no backslashes.
- Release tags containing `+` (e.g. `v2026-07-01+564c15b`) work unescaped in the provider URL — GitHub's download endpoint accepts them raw.
