# Release Workflow

CalVer (`YYYY-MM-DD+SHORT_SHA`) with automatic releases on green main builds.

```yaml
# .github/workflows/release.yml
name: Release

on:
  workflow_dispatch:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

permissions:
  contents: write

jobs:
  build:
    if: >-
      github.event_name == 'workflow_dispatch'
      || github.event.workflow_run.conclusion == 'success'
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Calculate version
        id: version
        run: |
          CALVER=$(date -u +"%Y-%m-%d")
          SHORT_SHA=$(git rev-parse --short HEAD)
          echo "version=${CALVER}+${SHORT_SHA}" >> $GITHUB_OUTPUT

      - name: Build
        run: |
          cargo build --release
          tar -czf <name>-aarch64-apple-darwin.tar.gz -C target/release <name>

      - name: Publish
        run: |
          VERSION="${{ steps.version.outputs.version }}"
          git tag "v${VERSION}"
          git push origin "v${VERSION}"
          gh release create "v${VERSION}" \
            --title "v${VERSION}" \
            --generate-notes \
            <name>-aarch64-apple-darwin.tar.gz
        env:
          GH_TOKEN: ${{ github.token }}
```

Adjust `runs-on` and archive name for target platform. Add matrix builds for cross-platform.

The build job exposes `outputs.version` so downstream jobs can reference the tag.

## DotSlash

[DotSlash](https://dotslash-cli.com) generates a small launcher file that fetches and caches the real binary on first run. Add a config file and a second job to the release workflow.

```json
// .github/dotslash-config.json
{
  "outputs": {
    "<name>": {
      "platforms": {
        "macos-aarch64": {
          "regex": "^<name>-aarch64-apple-darwin\\.tar\\.gz$",
          "path": "<name>"
        }
      }
    }
  }
}
```

Add a `dotslash` job to `release.yml` after the build job:

```yaml
  dotslash:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate DotSlash file
        uses: facebook/dotslash-publish-release@v1
        with:
          config: .github/dotslash-config.json
          tag: v${{ needs.build.outputs.version }}
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

This attaches a `<name>` DotSlash file to the release. Users download it, make it executable, and the binary self-updates from GitHub releases.
