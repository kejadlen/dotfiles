# Mutation testing

`cargo mutants` modifies your source code (replacing operators,
deleting calls, changing return values) and checks that at least one
test fails for each mutation. Surviving mutants indicate code that
tests execute but don't actually verify.

Run mutation testing separately from coverage — it's slow:

```bash
just mutants
```

## Workflow

1. Run `just mutants` after reaching 100% coverage.
2. For each surviving mutant, tighten an existing assertion (or
   add one) so the mutated behavior fails the test (see worked
   example below).
3. If a mutant is equivalent (same observable behavior) or
   unreachable (dead code behind `unreachable!`), add it to
   `.cargo/mutants.toml` with an explanation.
4. CI enforces zero missed mutants — a surviving mutant fails the
   build.

## Worked example: weak assertions hide bugs

A function with full line coverage and a passing test:

```rust
// src/order.rs
pub fn total(items: &[Item]) -> u32 {
    items.iter().map(|i| i.price).sum()
}
```

```rust
#[test]
fn computes_total() {
    let items = vec![Item::new(10), Item::new(20)];
    assert!(total(&items) > 0);
}
```

`just mutants` reports:

```
src/order.rs:3:5: replace total -> u32 with 1 ... NOT CAUGHT
```

`cargo-mutants` replaced the function body with `1`. The test still
passes — `1 > 0` is true. Coverage saw the line execute; the
assertion didn't notice the body was gutted.

The mutant points at a weak assertion. Tighten it from a property
("greater than zero") to a value ("exactly thirty"):

```rust
#[test]
fn computes_total() {
    let items = vec![Item::new(10), Item::new(20)];
    assert_eq!(total(&items), 30);
}
```

Re-run `just mutants`. The `with 1` mutant now fails (`assert_eq!(1,
30)` panics) and is caught. Other body-replacement mutants (`with
0`, `with u32::MAX`) are caught by the same assertion.

The lesson is general: every `assert!` predicate is a hint that the
test could be tighter. Replacing `>` with `==` (or `assert!` with
`assert_eq!`) usually buys mutation coverage for free.

## Where surviving mutants tend to live

- Functions whose tests assert on a property (`> 0`, `is_some()`,
  `len() > 1`) instead of a specific value.
- Side-effect functions called for their effect but not verified
  (`logger.record("x")` called, `logger.entries` not inspected).
- Boundary conditions where the only tested inputs sit far from the
  boundary, so `<` vs `<=` produce the same result.
- Error-construction code where the variant is matched but the
  payload isn't.

## Excluding equivalent mutants

Some mutations produce equivalent programs and can never be caught.
For example, changing `> 1` to `>= 1` when an earlier branch already
handled `== 1` — both versions behave identically.

Document each exclusion in `.cargo/mutants.toml` with a regex
pattern and a comment explaining why it's equivalent or unreachable:

```toml
# Equivalent mutant: the `== 1` branch above already handles len 1,
# so `> 1` and `>= 1` are equivalent in the else-if position.
exclude_re = [
    "my_file\\.rs:\\d+:\\d+: replace > with >= in some_function",
]
```

Every exclusion needs a comment. Undocumented exclusions hide real
gaps.
