---
name: rust
description: Use when writing, reviewing, scaffolding, releasing, or measuring coverage on Rust code — routes to references for style, project layout, testing, Dockerfile, and release
---

# Rust

Preferences for writing and shipping Rust. The actual guidance lives
in references — this file routes by task and lists the cross-cutting
principles that apply everywhere.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## When to read which reference

| Task | Read |
|------|------|
| Writing or reviewing Rust code | `style.md` |
| Scaffolding a new project | `scaffolding.md` + `binary.md` (CLI) or `server.md` (server) |
| Setting up a Dockerfile for a server | `dockerfile.md` |
| Debugging coverage gaps | `coverage.md` |
| Adding property tests | `property-testing.md` |
| Adding mutation testing | `mutation-testing.md` |
| Wiring `<NAME>_VERSION` into a binary | `versioning.md` |
| Releasing a CLI binary | `binary.md` (release section) |
| Deploying a server | `server.md` (deploy section) + `dockerfile.md` |

## Cross-cutting principles

These apply to every Rust project regardless of shape.

### Edition

`edition = "2024"` for new projects. Bump existing projects when
upstream dependencies require it, not preemptively.

### Project structure

Single crate with both library and binary targets. All domain logic
lives in the library; the binary is a thin shell that parses input,
calls the library, and renders output. `scaffolding.md` covers the
layout in detail.

### Errors

Library errors derive `thiserror::Error` *and* `miette::Diagnostic`.
The diagnostic codes and help text live on the variant itself, so
errors carry their own labels and source spans through tests, other
binaries, and HTTP handlers. Binaries return `miette::Result<()>` from
`main` and call `miette::set_panic_hook()` early.

### Logging

Use `tracing` and `tracing-subscriber` with `EnvFilter`. Never
`println!` for diagnostic output — `println!` belongs to user-facing
program output only.

### Filesystem

Use `fs-err` instead of `std::fs`. Bare `std::fs` errors omit the
path that failed. The Clippy configuration in `style.md` enforces
this.

### Cargo.lock

Commit `Cargo.lock` for binaries (CLIs and servers both). Builds
stay reproducible even though dependency versions in `Cargo.toml`
are unpinned (`"*"`). `cargo update` upgrades to the latest
compatible release without editing `Cargo.toml`.

### Task runner

Use `just`. The `justfile` template is in `scaffolding.md`.

### CI

GitHub Actions, with every `uses:` pinned to a commit SHA and a
version comment (`@<sha> # v4`). Never pin to a moving tag.

### Async runtime

`tokio` with `features = ["full"]` for both CLIs and servers.
Single-threaded runtimes are an opt-in micro-optimization, not a
default.
