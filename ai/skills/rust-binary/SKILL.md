---
name: rust-binary
description: Use when creating or updating a Rust binary project — covers preferred crate layout, dependencies, justfile, CI, coverage, release pipeline, and test harness
disable-model-invocation: true
---

# Rust binary preferences

Standards and preferences for Rust binary projects. Use this when scaffolding a new binary or bringing an existing one up to current standards.

*This is a self-improving skill — see the `self-improving-skills` skill.*

Read these companion files when working on their specific concerns:

- `property-testing.md` — hegeltest generators, composite generators, roundtrip patterns
- `mutation-testing.md` — cargo-mutants, `.cargo/mutants.toml`, exclusion workflow
- `versioning.md` — build.rs, CalVer, `<NAME>_VERSION` env var
- `release.md` — release workflow, DotSlash

## Project structure

Single crate with both library and binary targets. All domain logic lives in the library; the binary is a thin CLI shell.

```
project/
├── Cargo.toml
├── build.rs                # Sets <NAME>_VERSION for --version
├── Cargo.lock              # Committed — it's a binary.
├── justfile
├── .gitignore              # /target
├── .cargo/
│   └── mutants.toml        # Excludes equivalent/unreachable mutations.
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── src/
│   ├── lib.rs              # Library root — re-exports modules.
│   ├── error.rs            # thiserror enum.
│   ├── (domain modules)
│   └── bin/<name>/
│       ├── main.rs          # Entrypoint, clap, thin dispatch.
│       ├── output.rs        # Human/JSON output helpers.
│       └── commands/        # One module per subcommand group.
│           └── mod.rs
├── tests/
│   ├── cli.rs              # Integration tests via assert_cmd.
│   └── property.rs         # Hegeltest property tests.
└── migrations/             # If using a database.
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
clap_complete = "*"
color-eyre = "*"
thiserror = "*"
tokio = { version = "*", features = ["full"] }
tracing-subscriber = { version = "*", features = ["env-filter"] }

[dev-dependencies]
assert_cmd = "*"
hegeltest = "*"
predicates = "*"
tempfile = "*"
```

Key choices:

- `edition = "2024"` — latest stable edition.
- Unpinned dependencies (`"*"`) — `Cargo.lock` is committed (it's a binary), so builds are reproducible. Unpinned versions mean `cargo update` gets the latest compatible releases without editing `Cargo.toml`.
- `clap` with `derive` + `env` — declarative CLI with env var fallbacks.
- `clap_complete` — shell completion generation for bash, zsh, fish, etc.
- `color-eyre` — pretty error reports in the binary.
- `thiserror` — structured errors in the library.
- `hegeltest` — property-based testing built on the Hypothesis engine, with built-in shrinking.

## Entrypoint pattern

```rust
// src/bin/<name>/main.rs
mod commands;
mod output;

use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::Shell;
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
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
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
        Cli::command().print_help()?;
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

The `--completions` flag generates shell completions to stdout:

```bash
<name> --completions zsh > _<name>
<name> --completions bash > <name>.bash
<name> --completions fish > <name>.fish
```

## Error pattern

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
        --excl-line 'cov-excl-line|unreachable!' \
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

mutants:
    #!/usr/bin/env bash
    set -uo pipefail
    cargo mutants --timeout-multiplier 3 -j4
    rc=$?
    # 0 = all caught, 3 = timeouts (infinite loops from mutants, still caught).
    if [ "$rc" -eq 0 ] || [ "$rc" -eq 3 ]; then
        exit 0
    fi
    exit "$rc"

all: fmt clippy coverage

install:
    cargo install --locked --path .
```

Key design:

- `coverage` uses a separate `CARGO_TARGET_DIR` — prevents instrumented and non-instrumented artifacts from mixing, which causes phantom uncovered lines with grcov.
- 100% coverage on library code only — `--keep-only 'src/**' --ignore 'src/bin/**'`. Binary code is tested via integration tests but not measured.
- `covdir` output — machine-readable JSON, parsed with `jq` for a clean summary.
- Exclusion markers — `cov-excl-line`, `cov-excl-start`/`cov-excl-stop` for structurally unreachable code. The `unreachable!` macro is also excluded by default.
- `mutants` tolerates exit code 3 — `cargo mutants` returns 3 for timeouts (infinite loops caused by mutations). These count as caught because the mutant broke the program.

## CI workflow

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
      - uses: actions/checkout@SHA # v4
        with:
          persist-credentials: false
      - run: rustup component add clippy rustfmt llvm-tools
      - run: cargo install grcov cargo-mutants just
      - uses: astral-sh/setup-uv@SHA # v6
      - run: cargo fmt --check
      - run: just clippy coverage
      - run: just mutants
```

Pin all actions to commit SHAs with a version comment (`@<sha> # v4`). Resolve the SHA for each tag at generation time:

```bash
git ls-remote https://github.com/<owner>/<repo> <tag> | cut -f1
```

`cargo fmt --check` instead of `just fmt` — CI should fail on unformatted code, not silently fix it.

The `setup-uv` step is required because hegeltest uses `uv` to manage its Hypothesis backend.

## Testing

Unit tests live in each module, using `tempfile` for isolation when state is involved.

Integration tests in `tests/cli.rs` exercise the compiled binary end-to-end via `assert_cmd`:

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

Property tests in `tests/property.rs` use hegeltest. See `property-testing.md`.

Mutation testing via `just mutants` catches code that tests execute but don't verify. See `mutation-testing.md`.

## Prerequisites

```bash
rustup component add clippy rustfmt llvm-tools
cargo install grcov cargo-mutants just
```

hegeltest also requires [`uv`](https://docs.astral.sh/uv/) on `PATH` — it manages the Hypothesis engine automatically.

## Quick reference

| Task | Command |
|------|---------|
| Format | `just fmt` |
| Lint | `just clippy` |
| Coverage | `just coverage` |
| Mutation testing | `just mutants` |
| All checks | `just all` |
| Install from source | `just install` |
| Find uncovered lines | Change `-t covdir` to `-t markdown` in justfile |
