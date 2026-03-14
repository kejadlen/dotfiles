---
name: scaffolding-rust-binary
description: Use when creating a new Rust binary project from scratch — scaffolding the crate, justfile, CI, coverage, release pipeline, and test harness
---

# Creating a Rust Binary Project

Scaffold a single-crate Rust binary with library code, a justfile, 100% coverage enforcement, GitHub Actions CI, and CalVer releases.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Project Structure

Single crate with both library and binary targets. All domain logic lives in the library; the binary is a thin CLI shell.

```
project/
├── Cargo.toml
├── Cargo.lock              # committed — it's a binary
├── justfile
├── .gitignore              # /target
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── src/
│   ├── lib.rs              # Library root — re-exports modules
│   ├── error.rs            # thiserror enum
│   ├── (domain modules)
│   └── bin/<name>/
│       ├── main.rs          # Entrypoint, clap, thin dispatch
│       ├── output.rs        # Human/JSON output helpers
│       └── commands/        # One module per subcommand group
│           └── mod.rs
├── tests/
│   └── cli.rs              # Integration tests via assert_cmd
└── migrations/             # If using a database
```

## Cargo.toml

```toml
[package]
name = "<name>"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "<name>"
path = "src/bin/<name>/main.rs"

[dependencies]
clap = { version = "*", features = ["derive", "env"] }
color-eyre = "*"
thiserror = "*"
tokio = { version = "*", features = ["full"] }
tracing-subscriber = { version = "*", features = ["env-filter"] }

[dev-dependencies]
assert_cmd = "*"
predicates = "*"
tempfile = "*"
```

Key choices:
- **`edition = "2024"`** — latest stable edition.
- **Unpinned dependencies (`"*"`)** — `Cargo.lock` is committed (it's a binary), so builds are reproducible. Unpinned versions mean `cargo update` gets the latest compatible releases without editing `Cargo.toml`.
- **`clap` with `derive` + `env`** — declarative CLI with env var fallbacks.
- **`color-eyre`** — pretty error reports in the binary.
- **`thiserror`** — structured errors in the library.

## Entrypoint Pattern

```rust
// src/bin/<name>/main.rs
mod commands;
mod output;

use clap::{Parser, Subcommand};
use tracing_subscriber::{EnvFilter, fmt, prelude::*};

#[derive(Parser)]
#[command(name = "<name>", about = "<description>")]
struct Cli {
    #[arg(long, global = true)]
    json: bool,

    #[command(subcommand)]
    command: Commands,
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
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env())
        .init();

    let cli = Cli::parse();
    match cli.command {
        Commands::Example { command } => {
            commands::example::run(command, cli.json).await?;
        }
    }
    Ok(())
}
```

## Error Pattern

Library errors use `thiserror`. The binary uses `color_eyre::Result`.

```rust
// src/error.rs
#[derive(Debug, thiserror::Error)]
pub enum MyError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
}
```

## justfile

```just
default: all

fmt:
    cargo fmt --all

check:
    cargo check --workspace

clippy:
    cargo clippy --workspace -- -D warnings

coverage:
    #!/usr/bin/env bash
    set -euo pipefail
    export RUSTFLAGS="-Cinstrument-coverage"
    export CARGO_TARGET_DIR="target/coverage"
    export LLVM_PROFILE_FILE="target/coverage/profraw/%p-%m.profraw"
    rm -rf target/coverage
    cargo test --workspace -q
    REPORT=$(grcov target/coverage/profraw \
        --binary-path ./target/coverage/debug/ \
        -s . \
        -t covdir \
        --ignore-not-existing \
        --keep-only 'src/**' \
        --ignore 'src/bin/**' \
        --excl-line 'cov-excl-line' \
        --excl-start 'cov-excl-start' \
        --excl-stop 'cov-excl-stop')
    echo "$REPORT" | jq -r '
        def files:
            to_entries[] | .value |
            if .children then .children | files
            else "\(.name): \(.coveragePercent)% (\(.linesCovered)/\(.linesTotal))"
            end;
        .children | files
    '
    COVERAGE=$(echo "$REPORT" | jq '.coveragePercent')
    echo ""
    echo "Total: ${COVERAGE}%"
    if [ "$(echo "$COVERAGE < 100" | bc -l)" -eq 1 ]; then
        echo "ERROR: Coverage is below 100%"
        exit 1
    fi

all: fmt clippy coverage

install:
    cargo install --locked --path .
```

Key design:
- **`coverage` uses a separate `CARGO_TARGET_DIR`** — prevents instrumented and non-instrumented artifacts from mixing, which causes phantom uncovered lines with grcov.
- **100% coverage on library code only** — `--keep-only 'src/**' --ignore 'src/bin/**'`. Binary code is tested via integration tests but not measured.
- **`covdir` output** — machine-readable JSON, parsed with `jq` for a clean summary.
- **Exclusion markers** — `cov-excl-line`, `cov-excl-start`/`cov-excl-stop` for structurally unreachable code.

## CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: rustup component add clippy rustfmt llvm-tools
      - run: cargo install grcov
      - run: cargo install just
      - run: cargo fmt --check
      - run: just clippy coverage
```

`cargo fmt --check` instead of `just fmt` — CI should fail on unformatted code, not silently fix it.

## Release Workflow

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

## Testing

**Library tests**: Unit tests in each module, using `tempfile` for isolation when state is involved.

**Integration tests**: `tests/cli.rs` exercises the compiled binary end-to-end via `assert_cmd`.

```rust
// tests/cli.rs
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

## Prerequisites

```bash
rustup component add clippy rustfmt llvm-tools
cargo install grcov just
```

## Quick Reference

| Task | Command |
|------|---------|
| Format | `just fmt` |
| Lint | `just clippy` |
| Coverage | `just coverage` |
| All checks | `just all` |
| Install from source | `just install` |
| Find uncovered lines | Change `-t covdir` to `-t markdown` in justfile |
