---
name: dotslash
description: Use when adding, updating, or troubleshooting DotSlash binaries in bin/ — covers file creation, Rakefile integration, and the dotslash CLI helpers
---

# DotSlash Binaries

This repo uses [DotSlash](https://dotslash-cli.com) to manage binaries in `bin/`. DotSlash files are lightweight JSON wrappers that lazily fetch, verify, cache, and run executables. Only `macos-aarch64` platform entries are needed.

## Existing binaries

- `bin/jq` — tracks latest jqlang/jq release (bare binary, no archive)
- `bin/jj` — tracks latest jj-vcs/jj release (tar.gz archive)

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

The block receives the resolved tag and returns the asset filename. Ignore the tag when the name is fixed (as above), or interpolate it (e.g. `{ |tag| "jj-#{tag}-aarch64-apple-darwin.tar.gz" }`). Pass `path:` when the executable sits inside an archive subdirectory; it defaults to `name`, which is correct when the archive holds a single file at its root.

### 2. Generate and verify

```bash
rake dotslash:<name>
chmod +x bin/<name>
bin/<name> --help   # or whatever smoke test is appropriate
```

### Hand-writing the file (fallback)

When the helper doesn't fit — a non-GitHub host or an unusual URL scheme — build the entry by hand:

1. Find the asset with `gh release view --repo owner/repo --json tagName,assets` and pick the `macos-arm64` / `macos-aarch64` / `darwin-arm64` one.
2. Run `dotslash -- create-url-entry URL`. It computes size and blake3 hash and infers `format` from the URL suffix; you fill in `path`.
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

This regenerates the DotSlash files in `bin/` with current release artifacts, fetching each tool's latest tag dynamically via `gh release view`.

## DotSlash CLI reference

```bash
dotslash -- create-url-entry URL   # Generate platform entry from a URL
dotslash -- b3sum FILE             # Compute blake3 hash of a local file
dotslash -- sha256 FILE            # Compute sha256 hash of a local file
dotslash -- fetch DOTSLASH_FILE    # Fetch and print cached exe path (don't run)
dotslash -- parse DOTSLASH_FILE    # Parse and validate a dotslash file
dotslash -- clean                  # Clear the dotslash cache
dotslash -- cache-dir              # Print cache directory path
```

## Key details

- Use `blake3` (preferred) or `sha256` for the hash. The `create-url-entry` helper defaults to blake3.
- Providers are tried in order. Put the direct HTTP URL first (faster for public repos), then the GitHub Release provider (works when authenticated).
- The `format` field must be a recognized value: `tar.gz`, `tar.zst`, `tar.xz`, `tar.bz2`, `tar`, `zip`, `gz`, `zst`, `xz`, `bz2`, or omitted for uncompressed binaries. `tgz` is not valid; use `tar.gz`.
- The `path` must be a normalized relative UNIX path: no leading `./`, no `..`, no trailing `/`, no backslashes.
- Release tags containing `+` (e.g. `v2026-07-01+564c15b`) work unescaped in the provider URL, which is what the helper interpolates. `+` only means "space" in a query string, not in a path, so GitHub's download endpoint accepts it raw.
- The cache lives at `~/Library/Caches/dotslash` on macOS.
