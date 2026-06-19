---
name: dotslash
description: Use when adding, updating, or troubleshooting DotSlash binaries in bin/ — covers file creation, Rakefile integration, and the dotslash CLI helpers
---

# DotSlash Binaries

This repo uses [DotSlash](https://dotslash-cli.com) to manage binaries in `bin/`. DotSlash files are lightweight JSON wrappers that lazily fetch, verify, cache, and run executables. Only `macos-aarch64` platform entries are needed.

## Existing binaries

- `bin/jq` — tracks latest jqlang/jq release (bare binary, no archive)
- `bin/nvim` — tracks neovim/neovim nightly (tar.gz archive)
- `bin/pinch` — downloaded directly via `gh release download` (not a dotslash file)

## Adding a new DotSlash binary

### 1. Find the release artifact URL

Use `gh` to find the right asset name:

```bash
gh release view --repo owner/repo --json tagName,assets
```

Pick the `macos-arm64` / `macos-aarch64` / `darwin-arm64` asset.

### 2. Generate the platform entry

```bash
dotslash -- create-url-entry URL
```

This downloads the artifact, computes its size and blake3 hash, infers the format from the URL suffix, and prints a JSON entry. Review the output — you must fill in `path` yourself and verify `format` is correct.

### 3. Determine the `path` value

- **Bare binary** (no archive): `path` is the filename the binary should be saved as in the cache directory (e.g., `"jq"`). Omit `format`.
- **Archive** (tar.gz, zip, etc.): list the archive contents to find the executable path:

```bash
curl -sL URL | tar tzf - | grep bin/
```

Set `path` to the relative path within the archive (e.g., `"nvim-macos-arm64/bin/nvim"`).

### 4. Write the DotSlash file

Create `bin/<name>` with this structure:

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

Include both an HTTP provider (direct URL) and a GitHub Release provider (uses `gh` CLI, works with private repos). Mark the file executable with `chmod +x`.

### 5. Add to the Rakefile

Add an update block to the `update_dotslash` task in `Rakefile` so `rake update_dotslash` regenerates the file with fresh size/hash. Follow the existing pattern — use backticks with `dotslash -- create-url-entry` and `gh release view`, then `File.write` the result. See the jq and nvim blocks for examples.

### 6. Verify

```bash
bin/<name> --version   # or whatever smoke test is appropriate
```

## Updating existing binaries

Run:

```bash
rake update_dotslash
```

This regenerates all DotSlash files in `bin/` with current release artifacts. For tools tracking `latest` or a fixed tag, the Rakefile fetches the tag dynamically via `gh release view`. For tools tracking `nightly` (like nvim), the URL is stable but the size/hash change with each build.

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
- The cache lives at `~/Library/Caches/dotslash` on macOS.
