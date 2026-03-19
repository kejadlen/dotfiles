# Mutation Testing

`cargo mutants` modifies your source code (replacing operators, deleting calls, changing return values) and checks that at least one test fails for each mutation. Surviving mutants indicate code that tests execute but don't actually verify.

Run mutation testing separately from coverage — it's slow:

```bash
just mutants
```

## Excluding Equivalent Mutants

Some mutations produce equivalent programs. For example, changing `> 1` to `>= 1` when a prior branch already handled `== 1`. These can't be caught because the mutant behaves identically to the original.

Document exclusions in `.cargo/mutants.toml` with regex patterns and a comment explaining why each is equivalent or unreachable:

```toml
# Equivalent mutant: the `== 1` branch above already handles len 1,
# so `> 1` and `>= 1` are equivalent in the else-if position.
exclude_re = [
    "my_file\\.rs:\\d+:\\d+: replace > with >= in some_function",
]
```

Every exclusion needs a comment. Undocumented exclusions hide real gaps.

## Workflow

1. Run `just mutants` after reaching 100% coverage.
2. Surviving mutants mean tests reach the code but don't assert on its behavior. Add targeted assertions.
3. If a mutant is equivalent (same behavior) or unreachable (dead code behind `unreachable!`), add it to `.cargo/mutants.toml` with an explanation.
4. CI enforces zero missed mutants — a surviving mutant fails the build.
