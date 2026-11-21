# Rust CLI binaries

Project-type-specific guidance for command-line tools. Read
`scaffolding.md` first for shared project shape, then return here for
CLI-specific additions and the release workflow.

## Cargo.toml additions

On top of the baseline in `scaffolding.md`:

```toml
[dependencies]
clap = { version = "*", features = ["derive", "env"] }
clap_complete = "*"

[dev-dependencies]
assert_cmd = "*"
predicates = "*"
```

- `clap` with `derive` + `env` — declarative CLI with env var fallbacks.
- `clap_complete` — shell completion generation.
- `assert_cmd` + `predicates` — integration tests against the compiled
  binary.

## Source layout

```
src/bin/<name>/
├── main.rs          # Entrypoint, clap, thin dispatch.
├── output.rs        # Human/JSON output helpers.
└── commands/        # One module per subcommand group.
    └── mod.rs
```

## Entrypoint pattern

```rust
// src/bin/<name>/main.rs
mod commands;
mod output;

use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::Shell;
use miette::IntoDiagnostic as _;
use tracing_subscriber::{EnvFilter, fmt, prelude::*};

#[derive(Parser)]
#[command(name = "<name>", about = "<description>")]
struct Cli {
    #[arg(long, global = true)]
    json: bool,

    /// Generate shell completions and exit.
    #[arg(long, value_enum)]
    completions: Option<Shell>,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    #[command(visible_alias = "x")]
    Example {
        #[command(subcommand)]
        command: commands::example::ExampleCommands,
    },
}

#[tokio::main]
async fn main() -> miette::Result<()> {
    miette::set_panic_hook();
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env())
        .init();

    let cli = Cli::parse();

    if let Some(shell) = cli.completions {
        clap_complete::generate(
            shell,
            &mut Cli::command(),
            "<name>",
            &mut std::io::stdout(),
        );
        return Ok(());
    }

    let Some(command) = cli.command else {
        Cli::command().print_help().into_diagnostic()?;
        return Ok(());
    };

    match command {
        Commands::Example { command } => {
            commands::example::run(command, cli.json).await?;
        }
    }
    Ok(())
}
```

Notes:

- `miette::Result<()>` is the binary's return type. Errors surface
  with their diagnostic codes and any `#[diagnostic(help(...))]`
  guidance.
- `miette::set_panic_hook()` makes panics render with the same
  fancy formatting as recoverable errors.
- The `--completions` flag generates shell completions to stdout:

  ```bash
  <name> --completions zsh > _<name>
  <name> --completions bash > <name>.bash
  <name> --completions fish > <name>.fish
  ```

## Integration testing

`tests/cli.rs` exercises the compiled binary end-to-end via
`assert_cmd`:

```rust
use assert_cmd::Command;
use assert_cmd::cargo::cargo_bin_cmd;

fn cmd() -> Command {
    cargo_bin_cmd!("<name>")
}

#[test]
fn shows_help() {
    cmd().arg("--help").assert().success();
}
```

`cargo_bin_cmd!` expands to `assert_cmd::Command::new(...)`, so it needs
no conversion — wrapping it in `Command::from` trips
`clippy::useless_conversion`. Pass the bin target name explicitly: the
no-argument form resolves the *package* name, which differs from the
binary name whenever the crate is named something like `<name>-cli`.

Integration tests are compiled with `--test`, so `cfg(test)` is set and
the `#![cfg_attr(test, allow(...))]` panic-lint exemption from
`scaffolding.md` applies here too.

## Release

CalVer (`YYYY-MM-DD-HHMM+SHORT_SHA`, UTC) with automatic releases on
green main builds. `HHMM` keeps tags unique across several pushes in a
day. Wire `<NAME>_VERSION` via `build.rs` — see `versioning.md`.

Release is a reusable workflow that CI calls once its checks pass on a
push to main:

```yaml
# .github/workflows/ci.yml, after the check jobs
  release:
    needs: [zizmor, checks]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: write # create the release.
    uses: $/.github/workflows/release.yml
```

Don't trigger it with `workflow_run` instead. zizmor fails it as a
dangerous trigger, `github.sha` there is main's tip rather than the
commit CI tested, and its `branches` filter also matches a fork PR's
branch named `main`. `$/` is GitHub's self-repository syntax; zizmor's
`self-repository` audit flags `./`.

```yaml
# .github/workflows/release.yml
name: Release

on:
  workflow_call:
  workflow_dispatch:

permissions: {}

jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      # One job stamps the time so every matrix build agrees on it.
      - name: Calculate version
        id: version
        run: echo "version=$(date -u +%Y-%m-%d-%H%M)+${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"

  build:
    needs: version
    strategy:
      matrix:
        include:
          - target: aarch64-apple-darwin
            runs-on: macos-latest
          # musl links statically, so the binary doesn't depend on the runner's glibc.
          - target: x86_64-unknown-linux-musl
            runs-on: ubuntu-latest
          - target: aarch64-unknown-linux-musl
            runs-on: ubuntu-24.04-arm
    runs-on: ${{ matrix.runs-on }}
    permissions:
      contents: read # checkout.
    steps:
      - uses: actions/checkout@SHA # v6
        with:
          persist-credentials: false
      - name: Build
        run: |
          rustup target add "${TARGET}"
          cargo build --release --locked --target "${TARGET}"
          tar -czf "<name>-${TARGET}.tar.gz" -C "target/${TARGET}/release" <name>
        env:
          TARGET: ${{ matrix.target }}
          <NAME>_VERSION: ${{ needs.version.outputs.version }}
      - uses: actions/upload-artifact@SHA # v7
        with:
          name: <name>-${{ matrix.target }}
          path: <name>-${{ matrix.target }}.tar.gz
          if-no-files-found: error

  publish:
    needs: [version, build]
    runs-on: ubuntu-latest
    permissions:
      contents: write # create the release.
    steps:
      - uses: actions/download-artifact@SHA # v8
        with:
          # The run's artifacts include any CI uploaded.
          pattern: <name>-*
          merge-multiple: true
      - name: Publish
        run: |
          gh release create "v${VERSION}" \
            --repo "${GITHUB_REPOSITORY}" \
            --title "v${VERSION}" \
            --generate-notes \
            --target "${GITHUB_SHA}" \
            <name>-*.tar.gz
        env:
          GH_TOKEN: ${{ github.token }}
          VERSION: ${{ needs.version.outputs.version }}
```

When a dependency compiles C through `cc` (check with
`cargo tree -e build -i cc`), add `sudo apt-get install -y
musl-tools` on the Linux runners so a musl-targeting compiler exists.

Publishing in its own job means a failed build leaves no partial
release. `gh` needs `--repo` because the publish job has no checkout.

### DotSlash

[DotSlash](https://dotslash-cli.com) generates a small launcher file
that fetches and caches the real binary on first run. Add a config
file and a second job to the release workflow.

```json
// .github/dotslash-config.json
{
  "outputs": {
    "<name>": {
      "platforms": {
        "macos-aarch64": {
          "regex": "^<name>-aarch64-apple-darwin\\.tar\\.gz$",
          "path": "<name>"
        },
        "linux-x86_64": {
          "regex": "^<name>-x86_64-unknown-linux-musl\\.tar\\.gz$",
          "path": "<name>"
        },
        "linux-aarch64": {
          "regex": "^<name>-aarch64-unknown-linux-musl\\.tar\\.gz$",
          "path": "<name>"
        }
      }
    }
  }
}
```

Add a `dotslash` job to `release.yml` after the publish job:

```yaml
  dotslash:
    needs: [version, publish]
    runs-on: ubuntu-latest
    permissions:
      contents: write # upload release assets.
    steps:
      - uses: facebook/dotslash-publish-release@SHA # v2
        with:
          config: .github/dotslash-config.json
          tag: v${{ needs.version.outputs.version }}
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

The job needs no checkout: the action fetches its config through the
API at `GITHUB_SHA` and calls `gh` with `--repo`.

This attaches a `<name>` DotSlash file to the release. Users download
it, make it executable, and the binary self-updates from GitHub
releases.

### Local install

For local distribution and dogfooding:

```bash
just install   # cargo install --locked --path .
```
