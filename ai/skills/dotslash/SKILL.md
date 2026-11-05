---
name: dotslash
description: Use when adding, updating, or troubleshooting DotSlash binaries in bin/ — covers file creation, Rakefile integration, and the dotslash CLI helpers
---

# DotSlash Binaries

This repo uses [DotSlash](https://dotslash-cli.com) to manage binaries in `bin/`. DotSlash files are lightweight JSON wrappers that lazily fetch, verify, cache, and run executables. Each file covers `macos-aarch64`, `linux-aarch64`, and `linux-x86_64`, minus any platform upstream doesn't publish. Run `dotslash --help` for the full CLI; `create-url-entry` is the only subcommand these workflows use.

## Adding a new DotSlash binary

The `update_dotslash_release` helper in `Rakefile` generates the file for you — you rarely hand-write the JSON.

### 1. Add a Rake task

In the `dotslash` namespace, add a task that calls the helper, then list `<name>` in the `all` task. The helper resolves the latest tag with `gh release view`, runs `create-url-entry`, and writes `bin/<name>`:

```ruby
desc "Update jj"
task(:jj) do
  update_dotslash_release(name: "jj", repo: "jj-vcs/jj") do |tag|
    {
      "macos-aarch64" => "jj-#{tag}-aarch64-apple-darwin.tar.gz",
      "linux-aarch64" => "jj-#{tag}-aarch64-unknown-linux-musl.tar.gz",
      "linux-x86_64" => "jj-#{tag}-x86_64-unknown-linux-musl.tar.gz",
    }
  end
end
```

The block receives the resolved tag and returns a hash of DotSlash platform to asset filename. Ignore the tag when the names are fixed, or interpolate it (as above). Leave out a platform upstream doesn't publish. On Linux, prefer a `musl` asset over `gnu` when both exist, since it's statically linked and runs regardless of the host's glibc.

Pass `path:` when the executable sits inside an archive subdirectory; it defaults to `name`, which is correct when the archive holds a single file at its root. When the subdirectory varies by platform or version (e.g. `cq-0.11.0-aarch64-apple-darwin/cq`), pass `path:` a proc — it receives each asset filename, so the generated `path` stays correct across platforms and release bumps:

```ruby
path: ->(asset) { "#{asset.delete_suffix(".tar.gz")}/cq" }
```

### 2. Generate and verify

```bash
rake dotslash:<name>
chmod +x bin/<name>
bin/<name> --help   # or whatever smoke test is appropriate
```

### Hand-writing the file (fallback)

Prefer extending `update_dotslash_release` over hand-writing JSON. Reserve hand-writing for cases the helper can't reach — a non-GitHub host, an unusual URL scheme, or a repo with no Rakefile to hold the helper (`Gusto/claude-code` ships DotSlash launchers inside plugins and has none):

1. Find the asset with `gh release view --repo owner/repo --json tagName,assets` and pick the asset for each platform (e.g. `darwin-arm64`, `linux-arm64`, `linux-amd64`).
2. Run `dotslash -- create-url-entry URL`. It computes size and hash and infers `format` from the URL suffix; you fill in `path`.
   On a private repo it can't do this — it fetches the URL with no auth and gets a 404. Download the asset instead (`gh release download <tag> --repo owner/repo --pattern '<asset>'`), then take `size` from `ls -l` and `digest` from `shasum -a 256`, and set `"hash": "sha256"` to match.
3. Determine `path`: for a bare binary, the filename to save as (e.g. `"jq"`, omit `format`); for an archive, the executable's relative path inside it (list contents with `curl -sL URL | tar tzf -`, or `tar tzf <file>` on the copy you downloaded above).
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
    },
    "linux-aarch64": { ... },
    "linux-x86_64": { ... }
  }
}
```

Include both an HTTP provider (direct URL, tried first) and a GitHub Release provider (uses `gh` CLI, works with private repos). On a private repo, omit the HTTP provider — `releases/download/...` needs auth the bare `url` provider never sends, so it is a dead entry that masks the real error when the fallback breaks.

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
