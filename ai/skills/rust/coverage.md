# Rust source-based code coverage

LLVM source-based coverage via `cargo-llvm-cov`, which wraps rustc's `-C instrument-coverage` flag.

## How it works

1. **Compile** with `-C instrument-coverage` — rustc inserts counters at coverage-relevant spans.
2. **Run** the instrumented binary — writes `.profraw` files.
3. **Merge** raw profiles into `.profdata` with `llvm-profdata merge`.
4. **Report** with `llvm-cov show` / `llvm-cov export`.

`cargo-llvm-cov` handles all four steps automatically.

## Prerequisites

```bash
rustup component add llvm-tools       # ships llvm-profdata + llvm-cov
cargo install cargo-llvm-cov          # convenience wrapper
```

## Quick reference

| Goal | Command |
|------|---------|
| Run tests + summary | `cargo llvm-cov` |
| Workspace coverage | `cargo llvm-cov --workspace` |
| Fail if below threshold | `cargo llvm-cov --fail-under-lines 100` |
| Text report (per-line) | `cargo llvm-cov --text` |
| HTML report | `cargo llvm-cov --html --open` |
| JSON export | `cargo llvm-cov --json` |
| LCOV export | `cargo llvm-cov --lcov --output-path lcov.info` |
| Include only specific test | `cargo llvm-cov --test cli` |
| Branch coverage (unstable) | `cargo llvm-cov --branch` |
| MC/DC coverage (unstable) | `cargo llvm-cov --mcdc` |
| Skip report, just instrument | `cargo llvm-cov --no-report` |
| Report from prior run | `cargo llvm-cov report --html` |
| Clean coverage artifacts | `cargo llvm-cov clean` |
| Show env vars it sets | `cargo llvm-cov show-env` |

## Filtering

```bash
# Only library tests
cargo llvm-cov --lib

# Only integration tests
cargo llvm-cov --test cli

# Only specific binary
cargo llvm-cov --bin myapp

# Exclude files from report
cargo llvm-cov --ignore-filename-regex 'bin/.*'

# Exclude package from test AND report
cargo llvm-cov --workspace --exclude some-crate

# Exclude from report but still test
cargo llvm-cov --workspace --exclude-from-report some-crate
```

## Reading the text report

```bash
cargo llvm-cov --text
```

Output shows each source line with execution count:

```
   46|      1|    fn display_formats_as_iso8601() {    # executed once
   32|      0|    fn encode_by_ref(                    # never executed
   10|       |use std::fmt;                            # non-executable (no counter)
```

Lines with `0` count are uncovered. Lines with no count are non-executable (declarations, imports, comments).

## Show missing lines

```bash
cargo llvm-cov --show-missing-lines
```

Appends a `Missing Lines` column to the summary table showing exact uncovered line ranges — useful for quickly spotting gaps without reading the full text report.

## cfg(coverage)

When built with `cargo-llvm-cov`, the cfg flags `coverage` and `coverage_nightly` are set. Use them to skip code that shouldn't run under coverage:

```rust
#[cfg(not(coverage))]
fn debug_only_thing() { /* ... */ }
```

Opt out with `--no-cfg-coverage` if these flags interfere.

## grcov (Mozilla)

[grcov](https://github.com/mozilla/grcov) is Mozilla's coverage tool. It processes `.profraw` files (same as `cargo-llvm-cov`) but also handles `.gcda` (GCC), lcov, JaCoCo, and Go coverage. Useful when you need output formats `cargo-llvm-cov` doesn't support (Cobertura, Coveralls, covdir) or when integrating with CI systems like GitLab that expect Cobertura XML.

### Prerequisites

```bash
rustup component add llvm-tools       # ships llvm-profdata + llvm-cov
cargo install grcov                   # or download from GitHub releases
```

### Workflow

```bash
# 1. Build and test with instrumentation
export RUSTFLAGS="-Cinstrument-coverage"
export LLVM_PROFILE_FILE="target/coverage/%p-%m.profraw"
cargo build
cargo test

# 2. Generate report with grcov
grcov target/coverage \
  --binary-path ./target/debug/ \
  -s . \
  -t html \
  --branch \
  --ignore-not-existing \
  --keep-only 'src/*' \
  -o ./target/debug/coverage/
```

The report lands in `target/debug/coverage/index.html`.

### Output Types

| `-t` value | Description |
|------------|-------------|
| `lcov` (default) | lcov INFO format — upload to Codecov, feed to `genhtml` |
| `html` | Self-contained HTML report with coverage badges |
| `cobertura` | Cobertura XML — GitLab CI integration, IDE support |
| `cobertura-pretty` | Pretty-printed Cobertura XML |
| `coveralls` | Coveralls JSON format |
| `coveralls+` | Coveralls with function-level information |
| `covdir` | Recursive JSON format |
| `files` | List of covered/uncovered source files |
| `markdown` | Human-readable markdown |

Multiple output types at once:

```bash
grcov target/coverage \
  --binary-path ./target/debug/ \
  -s . \
  --output-types html,cobertura \
  -o ./target/coverage/
```

### Common Options

```bash
# LCOV for Codecov upload
grcov . --binary-path ./target/debug/ -s . -t lcov --branch \
  --ignore-not-existing -o lcov.info

# Filter to only project source
grcov . --binary-path ./target/debug/ -s . -t html \
  --keep-only 'src/*' \
  --ignore 'src/bin/*' \
  -o coverage/

# Coveralls upload
grcov . --binary-path ./target/debug/ -s . -t coveralls \
  --token "$COVERALLS_TOKEN" > coveralls.json

# Exclude lines with marker comments
grcov . --binary-path ./target/debug/ -s . -t lcov \
  --excl-line 'LCOV_EXCL_LINE' \
  --excl-start 'LCOV_EXCL_START' \
  --excl-stop 'LCOV_EXCL_STOP'
```

### When to Use grcov vs cargo-llvm-cov

| Scenario | Prefer |
|----------|--------|
| Quick local coverage check | `cargo-llvm-cov` — single command, no env vars |
| Fail CI on threshold | `cargo-llvm-cov` — `--fail-under-lines` built in |
| GitLab CI with Cobertura | `grcov` — native Cobertura output |
| Coveralls integration | `grcov` — native Coveralls format |
| Multiple output formats at once | `grcov` — `--output-types html,cobertura` |
| Coverage badges for GitHub Pages | `grcov` — generates badges + `coverage.json` |
| Mixed language project (Rust + C) | `grcov` — handles `.gcda` + `.profraw` together |
| Doctests coverage | `cargo-llvm-cov` — `--doctests` flag (nightly) |

## Manual workflow (without cargo-llvm-cov or grcov)

For environments where neither wrapper is available:

```bash
# 1. Build with coverage
RUSTFLAGS="-C instrument-coverage" cargo test --no-run

# 2. Run tests (produces .profraw files)
LLVM_PROFILE_FILE="coverage-%p-%m.profraw" cargo test

# 3. Merge profiles
llvm-profdata merge -sparse *.profraw -o coverage.profdata

# 4. Find the test binary
BINARY=$(cargo test --no-run --message-format=json 2>/dev/null \
  | jq -r 'select(.executable) | .executable')

# 5. Generate report
llvm-cov show "$BINARY" \
  --instr-profile=coverage.profdata \
  --format=html \
  --output-dir=coverage/ \
  --Xdemangler=rustfilt

# Or export as LCOV
llvm-cov export "$BINARY" \
  --instr-profile=coverage.profdata \
  --format=lcov > lcov.info
```

Use `rustfilt` as demangler for readable Rust symbol names (`cargo install rustfilt`).

## Common pitfalls

**Multiple binaries**: `llvm-cov` needs all instrumented binaries passed via `-object`. `cargo-llvm-cov` handles this automatically. Manually, you must pass each binary:

```bash
llvm-cov show -object bin1 -object bin2 --instr-profile=merged.profdata
```

**Dead code appears uncovered**: Unreachable code still gets instrumented. If coverage matters, delete dead code rather than excluding it.

**Stale incremental artifacts with grcov**: Incremental compilation reuses old object files with outdated debug info, causing grcov to report phantom uncovered lines. Use a separate `CARGO_TARGET_DIR` for coverage builds so instrumented and non-instrumented artifacts never mix.

**Proc macros and build scripts**: Not instrumented by default. Use `--include-build-script` if needed. When using `--no-rustc-wrapper` with `--target`, proc macros won't show coverage.

**Doctests**: Experimental. Enable with `--doctests` (nightly only).

**Branch coverage is not practical yet**: Requires nightly. `--branch` enables it but LLVM's branch instrumentation doesn't map well to Rust's control flow — match arms, closures, `?` operator, and trait dispatch all produce misleading branch counts. False negatives are common enough that branch coverage targets create busywork rather than catching real gaps. Stick to line coverage for now.

**Phantom uncovered lines from `assert!` format strings**: Custom format strings in test assertions (e.g., `assert!(x, "expected {x}")`) create branches that only execute on failure, showing as uncovered. Either omit custom messages or exclude the test file from the report.

## Achieving 100% line coverage

When targeting full line coverage, use `--show-missing-lines` for a quick summary or the markdown/text report for exact locations.

With `cargo-llvm-cov`:

```bash
# Summary with uncovered line ranges
cargo llvm-cov --show-missing-lines

# Full per-line detail
cargo llvm-cov --text
```

With grcov:

```bash
# Markdown summary (good for CI output)
grcov target/coverage \
  --binary-path ./target/debug/ -s . -t markdown \
  --keep-only 'src/**' --ignore 'src/bin/**'
```

For structurally unreachable code (e.g., `unreachable!()` after exhaustive loops), use exclusion markers rather than deleting the safety check:

```rust
loop {
    if done { break; }
}
unreachable!(); // cov-excl-line
```

With grcov, configure the exclusion markers:

```bash
grcov ... \
  --excl-line 'cov-excl-line' \
  --excl-start 'cov-excl-start' \
  --excl-stop 'cov-excl-stop'
```

With `cargo-llvm-cov`, use `#[cfg(not(coverage))]` on functions or `cfg(coverage)` guards for blocks that shouldn't count.
