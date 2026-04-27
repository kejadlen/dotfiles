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
use tempfile::tempdir;

fn cmd() -> Command {
    Command::from(cargo_bin_cmd!("<name>"))
}

#[test]
fn shows_help() {
    cmd().arg("--help").assert().success();
}
```

## Release

CalVer (`YYYY-MM-DD+SHORT_SHA`) with automatic releases on green
main builds. Wire `<NAME>_VERSION` via `build.rs` — see
`versioning.md`.

```yaml
# .github/workflows/release.yml
name: Release

on:
  workflow_dispatch:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

permissions: {}

jobs:
  build:
    if: >-
      github.event_name == 'workflow_dispatch'
      || github.event.workflow_run.conclusion == 'success'
    runs-on: macos-latest
    permissions:
      contents: write # create GitHub release
    steps:
      - uses: actions/checkout@SHA # v4
        with:
          persist-credentials: false

      - name: Calculate version
        id: version
        run: |
          CALVER=$(date -u +"%Y-%m-%d")
          SHORT_SHA="${GITHUB_SHA::7}"
          echo "version=${CALVER}+${SHORT_SHA}" >> $GITHUB_OUTPUT

      - name: Build
        run: |
          <NAME>_VERSION="${STEPS_VERSION_OUTPUTS_VERSION}" cargo build --release
          tar -czf <name>-aarch64-apple-darwin.tar.gz -C target/release <name>
        env:
          STEPS_VERSION_OUTPUTS_VERSION: ${{ steps.version.outputs.version }}

      - name: Publish
        run: |
          VERSION="${STEPS_VERSION_OUTPUTS_VERSION}"
          gh release create "v${VERSION}" \
            --title "v${VERSION}" \
            --generate-notes \
            --target "${GITHUB_SHA}" \
            <name>-aarch64-apple-darwin.tar.gz
        env:
          GH_TOKEN: ${{ github.token }}
          STEPS_VERSION_OUTPUTS_VERSION: ${{ steps.version.outputs.version }}
```

Adjust `runs-on` and archive name for target platform. Add matrix
builds for cross-platform.

The build job exposes `outputs.version` so downstream jobs can
reference the tag.

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
    permissions:
      contents: write # upload release assets
    steps:
      - uses: actions/checkout@SHA # v4
        with:
          persist-credentials: false

      - name: Generate DotSlash file
        uses: facebook/dotslash-publish-release@SHA # v1
        with:
          config: .github/dotslash-config.json
          tag: v${{ needs.build.outputs.version }}
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

This attaches a `<name>` DotSlash file to the release. Users download
it, make it executable, and the binary self-updates from GitHub
releases.

### Local install

For local distribution and dogfooding:

```bash
just install   # cargo install --locked --path .
```
