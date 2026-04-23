---
name: rust-style
description: Use when writing, reviewing, or restructuring Rust code — covers project layout, module organization, file structure, item ordering, function design, and Clippy automation
source: https://epage.github.io/dev/rust-style/
---

# Rust style

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

Automation: no Clippy lint exists for this convention — enforce in code review.

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

Automation — add to `.clippy.toml`:

```toml
disallowed-methods = [
    { path = "std::iter::Iterator::for_each", reason = "prefer `for` for side-effects" },
    { path = "std::iter::Iterator::try_for_each", reason = "prefer `for` for side-effects" },
]
```

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

For async code, use `fs-err`'s tokio feature:

```toml
[dependencies]
fs-err = { version = "3", features = ["tokio"] }
```

```rust
use fs_err::tokio as fs;
```

The Clippy configuration below enforces this — `std::fs` functions and `std::fs::File` are disallowed so bare uses get caught at lint time rather than at 3 AM in production.

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
]

disallowed-types = [
    { path = "std::fs::File", reason = "use fs_err::File for better error messages" },
    { path = "std::fs::OpenOptions", reason = "use fs_err::OpenOptions" },
]
```
