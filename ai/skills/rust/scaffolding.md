# Project scaffolding

Standards for laying out a Rust project, common to CLIs and servers.
Read `binary.md` or `server.md` for project-type-specific additions
on top of this file.

## Project structure

Single crate with both library and binary targets. All domain logic
lives in the library; the binary is a thin shell.

```
project/
├── Cargo.toml
├── build.rs                # Sets <NAME>_VERSION (→ versioning.md).
├── Cargo.lock              # Committed — it's a binary.
├── justfile
├── .gitignore              # /target
├── .cargo/
│   └── mutants.toml        # Excludes equivalent/unreachable mutations.
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml         # Binaries only — see binary.md.
├── src/
│   ├── lib.rs              # Library root — re-exports modules.
│   ├── error.rs            # thiserror + miette::Diagnostic enum.
│   ├── (domain modules)
│   └── bin/<name>/
│       ├── main.rs          # Entrypoint — see binary.md or server.md.
│       └── ...
├── tests/
│   ├── cli.rs              # CLI integration tests via assert_cmd.
│   │                       # (or api.rs for server integration tests)
│   └── property.rs         # Hegeltest property tests (→ property-testing.md).
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
fs-err = "*"
miette = { version = "*", features = ["fancy"] }
thiserror = "*"
tokio = { version = "*", features = ["full"] }
tracing = "*"
tracing-subscriber = { version = "*", features = ["env-filter"] }

[dev-dependencies]
hegeltest = "*"
tempfile = "*"
```

Project-type-specific deps (`clap` for CLIs, `axum` for servers) go in
`binary.md` / `server.md` and are added on top of this baseline.

Key choices:

- `edition = "2024"` — latest stable edition.
- Unpinned dependencies (`"*"`) — `Cargo.lock` is committed (it's a
  binary), so builds are reproducible. Unpinned versions mean
  `cargo update` gets the latest compatible releases without editing
  `Cargo.toml`.
- `miette` with the `fancy` feature — pretty diagnostic rendering for
  binaries; the library still derives `miette::Diagnostic` even when
  the consumer is not the binary (e.g., when running tests).
- `thiserror` — structured errors in the library.
- `fs-err` — `std::fs` with paths in error messages (→ `style.md`).
- `hegeltest` — property-based testing built on the Hypothesis engine,
  with built-in shrinking.

## Error pattern

Library errors derive both `thiserror::Error` and `miette::Diagnostic`.
The binary returns `miette::Result<()>`.

```rust
// src/error.rs
use miette::Diagnostic;

#[derive(Debug, thiserror::Error, Diagnostic)]
pub enum MyError {
    #[error("not found: {0}")]
    #[diagnostic(
        code(myapp::not_found),
        help("check the input identifier and try again"),
    )]
    NotFound(String),

    #[error("io error: {0}")]
    #[diagnostic(code(myapp::io))]
    Io(#[from] std::io::Error),
}
```

The diagnostic codes and help text live on the variant itself, so
errors carry their own labels and source spans through tests, other
binaries, and HTTP handlers.

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

- `coverage` uses a separate `CARGO_TARGET_DIR` — prevents instrumented
  and non-instrumented artifacts from mixing, which causes phantom
  uncovered lines with grcov.
- 100% coverage on library code only — `--keep-only 'src/**'
  --ignore 'src/bin/**'`. Binary code is tested via integration tests
  but not measured.
- `covdir` output — machine-readable JSON, parsed with `jq` for a
  clean summary.
- Exclusion markers — `cov-excl-line`, `cov-excl-start`/
  `cov-excl-stop` for structurally unreachable code. The
  `unreachable!` macro is also excluded by default.
- `mutants` tolerates exit code 3 — `cargo mutants` returns 3 for
  timeouts (infinite loops caused by mutations). These count as
  caught because the mutant broke the program.

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

Pin all actions to commit SHAs with a version comment (`@<sha> # v4`).
Resolve the SHA for each tag at generation time:

```bash
git ls-remote https://github.com/<owner>/<repo> <tag> | cut -f1
```

`cargo fmt --check` instead of `just fmt` — CI should fail on
unformatted code, not silently fix it.

The `setup-uv` step is required because hegeltest uses `uv` to
manage its Hypothesis backend.

## Testing

Unit tests live in each module, using `tempfile` for isolation when
state is involved.

Integration tests differ by project type — see `binary.md` or
`server.md` for templates.

Property tests in `tests/property.rs` use hegeltest. See
`property-testing.md`.

Mutation testing via `just mutants` catches code that tests execute
but don't verify. See `mutation-testing.md`.

## Prerequisites

```bash
rustup component add clippy rustfmt llvm-tools
cargo install grcov cargo-mutants just
```

hegeltest also requires [`uv`](https://docs.astral.sh/uv/) on `PATH`
— it manages the Hypothesis engine automatically.

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
