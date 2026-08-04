# Rust style

*Source: <https://epage.github.io/dev/rust-style/>.*


Code is technical writing. Apply the inverted pyramid: lead with the most salient details, let readers decide how deep to go. Cross-references (functions, types) are cheap, but reader memory is not — optimize for skimming.

## Project structure

### Prefer `mod.rs` over `name.rs` (P-MOD)

When a module becomes a directory, use `mod.rs` as the root — not a sibling `name.rs` file. This keeps the module atomic for browsing, searching, moving, and renaming. A `name/` directory next to a `name.rs` is easy to miss on GitHub.

```
// Don't
src/
  stuff/
    stuff_files.rs
  stuff.rs
  lib.rs

// Do
src/
  stuff/
    stuff_files.rs
    mod.rs
  lib.rs
```

Automation: `clippy.self_named_module_files = "warn"`

### Directory roots only re-export (P-DIR-MOD)

`mod.rs` and `lib.rs` should contain only `mod` declarations and re-exports. All definitions live in topically named child files. The root is a table of contents, not a dumping ground.

Exceptions: an inline `mod prelude` in `lib.rs`, or the titular definition for the module (e.g., `fn compile` inside `mod compile`).

### Preludes only re-export (P-PRELUDE-MOD)

Prelude modules are import conveniences. Never put original logic in them.

### Avoid `#[path]` (P-PATH-MOD)

Use standard module lookup rules. `#[path]` makes project structure unpredictable. For platform-specific modules, use separate modules with `use ... as`:

```rust
#[cfg(windows)]
mod foo_windows;
#[cfg(windows)]
use foo_windows as foo;

#[cfg(unix)]
mod foo_unix;
#[cfg(unix)]
use foo_unix as foo;
```

### API maps to file layout (P-API)

A user should be able to navigate from an API path to its source file. Only re-export from child or sibling modules. Avoid inline modules (except `#[cfg(test)] mod tests` and inline preludes).

### Simple visibility (P-VISIBILITY)

Use only three levels: private (default), `pub(crate)`, or `pub`. Skip `pub(super)`, `pub(in path)`, and other scoped variants — they add friction during refactors with little benefit. If something needs finer-grained visibility, consider whether it should be its own crate.

## File structure

### Private imports first, then public (M-PRIV-PUB-USE)

Separate `use` and `pub use` with a blank line. Private imports are implementation details the reader skips over; public re-exports are part of the API.

```rust
use serde::Deserialize as _;
use std::collections::HashMap;

pub use regex::Regex;
```

### Limit private imports (M-PRIV-USE)

Import only items whose meaning is clear from the name alone. Qualify uncommon types at the call site — it provides context and avoids merge conflicts from churn in the import block.

Import candidates:
- Traits (as anonymous imports with `as _`)
- Heavily used types where intent is obvious (`HashMap`, `Vec`, `PathBuf`)

### Import items individually (M-SINGLE-USE)

One item per `use` statement. Compound imports (`use std::collections::{HashMap, HashSet}`) cause merge conflicts and are harder to edit line-by-line.

```rust
// Don't
use std::collections::{HashMap, hash_map::Entry};

// Do
use std::collections::HashMap;
use std::collections::hash_map::Entry;
```

### Central item first (M-ITEM-TOC)

The titular or quintessential item in a module comes first. It's what readers are looking for and provides context for everything else — a table of contents for the file.

### Type definition, then impl, then trait impls (M-TYPE-ASSOC, M-ASSOC-TRAIT)

Keep a type and its inherent impl together, followed by trait impls. Don't scatter type definitions at the top and impl blocks at the bottom.

```rust
pub struct Foo { /* ... */ }

impl Foo {
    // inherent methods
}

impl Display for Foo {
    // trait impl
}

pub struct Bar { /* ... */ }

impl Bar {
    // inherent methods
}
```

### Caller before callee (M-CALLER-CALLEE)

The caller provides context for the callee — place it first. The weaker the callee's abstraction, the closer it should sit to its caller. Think spatial locality: offer the reader's mental cache the same benefit you'd offer a CPU cache.

### Public before private (M-PUB-PRIV)

Public items come first in modules, structs, and impl blocks. They form the table of contents for the private details that follow.

### Use judgement when rules conflict (M-AMBIGUITY)

These ordering rules can tension with each other. They're listed roughly by priority, but context matters. Apply the one that best serves the reader in each situation.

## Function structure

### Group related logic (F-GROUP)

Blank lines separate logical "paragraphs" within a function. Each group should have a single purpose.

```rust
fn report_warning_count(&self, /* ... */) {
    let gctx = runner.bcx.gctx;

    runner.compilation.lint_warning_count += count.lints;

    let mut message = descriptive_pkg_name(/* ... */);
    message.push_str(" generated ");
    // ... builds up `message`

    gctx.shell().warn(message)
}
```

### Open blocks with output variables (F-OUT)

When a block builds up state, declare the output variable first. This announces the block's intent.

```rust
// Don't
let sentinel = get_sentinel();
let items = get_items();
let mut message = String::new();
for item in items { /* ... */ }

// Do
let mut message = String::new();
let sentinel = get_sentinel();
let items = get_items();
for item in items { /* ... */ }
```

### Blocks reflect business logic (F-VISUAL)

Use `if`/`else` and `match` for business-logic branches. Use early returns for non-business bookkeeping (validation, preconditions). Use combinators (`Option`, `Result`, `Iterator` methods) for non-business transformations.

```rust
// Don't — bookkeeping steals the spotlight
if let Some(foo) = foo {
    if case {
        return Ok(/* ... */);
    }
    Ok(/* ... */)
} else {
    Err(/* ... */)
}

// Do — bookkeeping is flat, business logic gets the block
let foo = foo.ok_or_else(|| /* ... */)?;
if case {
    Ok(/* ... */)
} else {
    Ok(/* ... */)
}
```

### Pure xor mutability (F-PURE-MUT)

Don't mix mutation with pure expressions. If a block uses an `if` as an expression, don't also mutate variables inside it. Either commit to statements-with-side-effects or pure-expression style.

```rust
// Don't — mutation hidden in an expression
let mut case = false;
let foo = if something {
    case = true;
    // ...
} else {
    // ...
};

// Do — commit to one style
let (foo, case) = if something {
    (/* ... */, true)
} else {
    (/* ... */, false)
};
```

Exceptions: invisible side effects (caching, logging).

### Keep combinators pure (F-COMBINATOR)

Closures passed to `map`, `filter`, `flat_map`, etc. should not have business-logic side effects. Readers skim combinators and won't expect mutations. Use `for` loops when you need side effects.

```rust
// Don't
list.map(transform).for_each(collect);

// Do
for item in list.map(transform) {
    collect(item);
}
```

The Clippy configuration below disallows `for_each` and `try_for_each` so bare uses get caught at lint time.

## Dependencies

### Use `fs-err` instead of `std::fs`

The `fs-err` crate is a drop-in replacement for `std::fs` that includes the file path in every error message. Bare `std::fs` errors say things like "No such file or directory (os error 2)" with no indication of which path failed — useless in any non-trivial program.

Add `fs-err` to `Cargo.toml` and import it in place of `std::fs`:

```rust
// Don't
use std::fs;
let contents = fs::read_to_string("config.toml")?;

// Do
use fs_err as fs;
let contents = fs::read_to_string("config.toml")?;
```

For async code, enable the tokio feature:

```toml
[dependencies]
fs-err = { version = "*", features = ["tokio"] }
```

```rust
use fs_err::tokio as fs;
```

The Clippy configuration below enforces this — `std::fs` functions and `std::fs::File` are disallowed so bare uses get caught at lint time rather than at 3 AM in production.

### Use `jiff` instead of `chrono`

[`jiff`](https://docs.rs/jiff) is a modern date/time crate by the
author of `regex` and `ripgrep`. Prefer it over `chrono` for new
code.

Why:

- Time-zone aware by default. `Zoned`, `Timestamp`, and `civil::DateTime`
  are distinct types, so DST and offset bugs are caught at the type
  level instead of by reading docs.
- Bundles the IANA tz database — no separate `chrono-tz` dependency.
- Strict arithmetic with `Span` (calendar-aware) and `SignedDuration`
  (absolute) keeps "add 1 month" and "add 30 days" explicit.
- Smaller dependency footprint and faster compile times.

```toml
[dependencies]
jiff = "*"
```

```rust
use jiff::{Timestamp, Zoned};

let now = Timestamp::now();
let local = now.in_tz("America/Los_Angeles")?;
```

`chrono` is still appropriate when an existing dependency forces it
(e.g., `sqlx` row decoding); convert at the boundary rather than
spreading it through new code.

The Clippy configuration below disallows `chrono` types so the
distinction is enforced at lint time.

## OS boundaries

Rust types only protect what they model. Crossing the OS↔Rust boundary
means picking the type that matches what the OS actually returns —
which is usually bytes, not text.

- Filesystem paths: `Path` / `PathBuf` / `OsStr` / `OsString`. Don't
  round-trip through `String`. Paths are arbitrary bytes on Unix and
  UTF-16 on Windows; `String` is neither.
- Process arguments and environment: `OsString`. Reach for
  `std::env::args_os()` and `std::env::var_os()`, not `args()` /
  `var()`.
- File or stream content of unknown encoding: `Vec<u8>` / `&[u8]`. Use
  `std::io::Write::write_all` rather than `print!` / `println!` for
  bytes that came in as bytes — the formatting macros assume UTF-8 and
  will round-trip through `&str`.
- `String::from_utf8_lossy` silently replaces invalid bytes with
  U+FFFD. That's a corruption hazard for filenames, stream content, or
  anything that came from another process. Reach for it only when
  you've already decided the input *is* text.

The corollary in the disallowed-methods list flags
`String::from_utf8_lossy` so the choice surfaces at lint time rather
than in a postmortem.

## Panic discipline

Code that processes external input must not panic on it. `unwrap`,
`expect`, raw indexing (`xs[i]`), and unchecked arithmetic (`a + b`)
all abort the process — fine for invariants the program controls,
but a denial-of-service vector when the input came from a user, a
file, or another process.

Replace them with their fallible counterparts:

| Panicking | Fallible alternative |
|---|---|
| `xs[i]` | `xs.get(i).ok_or(...)?` |
| `s.parse::<u32>().unwrap()` | `s.parse::<u32>()?` |
| `a + b` (where overflow is possible) | `a.checked_add(b).ok_or(...)?` |
| `usize::try_from(n).unwrap()` | `usize::try_from(n)?` |
| `slice[start..end]` | `slice.get(start..end).ok_or(...)?` |

The `[lints.clippy]` block in the `Cargo.toml` template (see
`scaffolding.md`) makes the relevant lints — `unwrap_used`,
`expect_used`, `panic`, `indexing_slicing`, `arithmetic_side_effects`
— warnings. Opt out per-call-site with
`#[allow(clippy::unwrap_used)]` and a comment explaining why the
invariant holds. Don't disable a lint crate-wide to silence a noisy
test module; gate tests with `#![cfg_attr(test, allow(...))]` instead.

## Clippy configuration summary

Collect these in `.clippy.toml` at the crate root:

```toml
disallowed-methods = [
    { path = "std::iter::Iterator::for_each", reason = "prefer `for` for side-effects" },
    { path = "std::iter::Iterator::try_for_each", reason = "prefer `for` for side-effects" },
    { path = "std::fs::read", reason = "use fs_err::read for better error messages" },
    { path = "std::fs::read_to_string", reason = "use fs_err::read_to_string" },
    { path = "std::fs::write", reason = "use fs_err::write" },
    { path = "std::fs::copy", reason = "use fs_err::copy" },
    { path = "std::fs::create_dir", reason = "use fs_err::create_dir" },
    { path = "std::fs::create_dir_all", reason = "use fs_err::create_dir_all" },
    { path = "std::fs::remove_file", reason = "use fs_err::remove_file" },
    { path = "std::fs::remove_dir", reason = "use fs_err::remove_dir" },
    { path = "std::fs::remove_dir_all", reason = "use fs_err::remove_dir_all" },
    { path = "std::fs::rename", reason = "use fs_err::rename" },
    { path = "std::fs::metadata", reason = "use fs_err::metadata" },
    { path = "std::fs::symlink_metadata", reason = "use fs_err::symlink_metadata" },
    { path = "std::fs::canonicalize", reason = "use fs_err::canonicalize" },
    { path = "std::fs::hard_link", reason = "use fs_err::hard_link" },
    { path = "std::fs::read_dir", reason = "use fs_err::read_dir" },
    { path = "std::fs::read_link", reason = "use fs_err::read_link" },
    { path = "std::fs::set_permissions", reason = "use fs_err::set_permissions" },
    { path = "std::string::String::from_utf8_lossy", reason = "lossy at OS boundaries — consider OsStr/Path or stay in &[u8]; if input really is text, suppress with an #[allow] and a comment" },
]

disallowed-types = [
    { path = "std::fs::File", reason = "use fs_err::File for better error messages" },
    { path = "std::fs::OpenOptions", reason = "use fs_err::OpenOptions" },
    { path = "chrono::DateTime", reason = "use jiff::Zoned or jiff::Timestamp" },
    { path = "chrono::NaiveDateTime", reason = "use jiff::civil::DateTime" },
    { path = "chrono::NaiveDate", reason = "use jiff::civil::Date" },
    { path = "chrono::NaiveTime", reason = "use jiff::civil::Time" },
    { path = "chrono::Duration", reason = "use jiff::Span or jiff::SignedDuration" },
]
```

Lint *levels* live in `Cargo.toml` under `[lints.clippy]`, not here —
`.clippy.toml` configures lint behavior (thresholds, disallowed paths)
and rejects anything that isn't a known config key. This trips up
`self_named_module_files`: it's a lint with no configurable behavior, so
setting `self-named-module-files = "warn"` in `.clippy.toml` errors with
an unknown-field message. It belongs in `[lints.clippy]` alongside the
panic-discipline lints (`unwrap_used`, `expect_used`, `panic`,
`indexing_slicing`, `arithmetic_side_effects`). The template is in
`scaffolding.md`.
