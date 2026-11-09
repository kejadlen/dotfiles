---
name: testing
description: Use when designing, writing, or reviewing tests — deciding what to test, structuring a suite, adding randomized or exhaustive tests, making failures reproducible, or dealing with slow or flaky tests
---

# Testing

How I design test suites. The defaults are what I follow; the last section
lists ideas to weigh case by case. Points drawn from elsewhere link their
source.

*This is a self-improving skill. If you used it and it came up short — a missing command, flag, gotcha, or workflow — invoke the `self-improving-skills` skill and follow it before you finish.*

## Defaults

### Test features at the boundary

A suite exists to make change cheap. Test what the software does at its
boundary — the public API for a library, what the user sees for an app — not
its internal functions. If rewriting the implementation would break the
tests, they pin code, not features. ([How to Test][how])

[how]: https://matklad.github.io/2021/05/31/how-to-test.html

### Substitute explicitly

When a test needs a stand-in, inject it as a dependency, or subclass the real
type with one that honors its contract (Liskov substitution). Never
monkeypatch.

### Optimize purity, not size

Classify tests by purity (how much IO, threading, and timing they depend on)
and extent (how much code they exercise), not "unit" versus "integration."
Each step toward pure, single-threaded computation buys about half an order
of magnitude of speed and removes a source of flakes, so push hard on purity.
Let extent be whatever the feature needs. ([Unit and Integration Tests][unit])

Get purity through sans-IO design: the caller does IO and passes values in,
and the core computes and returns values.

[unit]: https://matklad.github.io/2022/07/04/unit-and-integration-tests.html

### Make new cases data

Shape the code under test as value in, value out, so a new case is data — an
inline string or a file under `test_data/` — not a new test function. Adding
a test must be trivial, or people stop adding them.

### Generate inputs before writing examples

Reach for a randomized or property test first, and fall back to examples or
snapshots when inputs can't be generated. Keep a couple of example tests as
smoke checks. Write property tests with the `hegel-skill:hegel` skill.

- Bugs live in small, tricky inputs. When the domain allows it, enumerate
  every input up to a bound instead of sampling: a generator that takes an
  RNG becomes an enumerator when the RNG is rigged to emit every
  sequence. ([Generate All the Things][gen])
- Pass the RNG explicitly; never use an ambient global. Every randomized
  failure prints a seed that reproduces it. ([On Random Numbers][rng])
- When a fuzzer misses a bug found some other way, fix the fuzzer until it
  finds the bug, then fix the code. ([Finding Bugs][bugs])

[gen]: https://matklad.github.io/2021/11/07/generate-all-the-things.html
[rng]: https://matklad.github.io/2023/01/04/on-random-numbers.html
[bugs]: https://matklad.github.io/2026/09/19/finding-bugs.html

### Keep main green

Merge through a queue that tests the merge result, so main always passes.
Then every failure on main is a flake: keep a list of them and fix the most
frequent first. ([Catch Flakes On Main][flakes])

[flakes]: https://matklad.github.io/2026/05/14/catch-flakes-on-main.html

### Keep the suite fast

Gate slow tests behind a runtime env var such as `RUN_SLOW_TESTS`, skipped
locally and run in CI — not behind conditional compilation. Print each
test's duration so slowness stays visible.

## Worth weighing

Valid, but not defaults:

- Route every test through one `check(input, expected)` helper, so an API
  change touches one place. ([How to Test][how])
- Prefer snapshot tests, where the framework rewrites the expected literal
  in update mode, over hand-written expectations. ([Underusing Snapshot
  Testing][snap], [Snapshot Testing For the Masses][snap-tb])
- Compare against an oracle: a naive implementation, a model, or a second
  implementation. ([Finding Bugs][bugs])
- Swarm testing: randomize operation weights per run so rare combinations
  happen. ([Swarm Testing Data Structures][swarm])
- Coverage marks tie a branch to the test that exercises it, which keeps
  negative tests honest. ([A Trick For Test Maintenance][marks])
- Treat any repository check — lint, licenses, binary size — as a test, and
  ratchet improvements against a list of known violators. ([Of Rats and
  Ratchets][rats])
- Deeper techniques: finite-entropy PRNGs that shrink for free ([Test Case
  Minimization][min], [Random Fuzzy Thoughts][fuzzy]), deterministic thread
  interleavings ([Properly Testing Concurrent Data Structures][conc]),
  liveness simulation ([Simulation Testing For Liveness][live]), and fuzzers
  at several levels of realism ([A Tale Of Four Fuzzers][four]).
- Rust: one integration-test crate and `doctest = false` in large
  workspaces. ([Delete Cargo Integration Tests][cargo])

[snap]: https://matklad.github.io/2025/04/15/underusing-snapshot-testing.html
[snap-tb]: https://tigerbeetle.com/blog/2024-05-14-snapshot-testing-for-the-masses
[swarm]: https://tigerbeetle.com/blog/2025-04-23-swarm-testing-data-structures
[marks]: https://matklad.github.io/2018/06/18/a-trick-for-test-maintenance.html
[rats]: https://matklad.github.io/2024/01/03/of-rats-and-ratchets.html
[min]: https://matklad.github.io/2026/04/20/test-case-minimization.html
[fuzzy]: https://tigerbeetle.com/blog/2023-03-28-random-fuzzy-thoughts
[conc]: https://matklad.github.io/2024/07/05/properly-testing-concurrent-data-structures.html
[live]: https://tigerbeetle.com/blog/2023-07-06-simulation-testing-for-liveness
[four]: https://tigerbeetle.com/blog/2025-11-28-tale-of-four-fuzzers
[cargo]: https://matklad.github.io/2021/02/27/delete-cargo-integration-tests.html
