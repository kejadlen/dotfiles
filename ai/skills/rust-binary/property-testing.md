# Property testing

`tests/property.rs` uses hegeltest to verify invariants across randomly generated inputs. Hegeltest is built on the Hypothesis engine — it generates test data, finds failures, and shrinks to minimal counterexamples automatically.

Hegeltest requires [`uv`](https://docs.astral.sh/uv/) on `PATH` (it manages its Hypothesis backend via uv).

## Basic usage

Test functions take a `TestCase` parameter and draw values from generators:

```rust
use hegel::TestCase;
use hegel::generators::{integers, text, vecs};

#[hegel::test]
fn roundtrip_serialization(tc: TestCase) {
    let input = tc.draw(integers::<i32>());
    let serialized = my_crate::serialize(&input).unwrap();
    let deserialized: i32 = my_crate::deserialize(&serialized).unwrap();
    assert_eq!(input, deserialized);
}
```

## Custom generators with `#[hegel::composite]`

Define reusable generators for domain types using `#[hegel::composite]`:

```rust
use hegel::TestCase;
use hegel::generators::{integers, text, booleans, optional};

#[derive(Debug, PartialEq)]
struct MyStruct {
    name: String,
    count: i32,
    enabled: bool,
    ratio: f64,
}

#[hegel::composite]
fn my_struct_generator(tc: TestCase) -> MyStruct {
    let name = tc.draw(text());
    let count = tc.draw(integers::<i32>());
    let enabled = tc.draw(booleans());
    let ratio = tc.draw(
        hegel::generators::floats::<f64>()
            .allow_nan(false)
            .allow_infinity(false),
    );
    MyStruct { name, count, enabled, ratio }
}

#[hegel::test]
fn roundtrip(tc: TestCase) {
    let val = tc.draw(my_struct_generator());
    let serialized = my_crate::serialize(&val).unwrap();
    let deserialized: MyStruct = my_crate::deserialize(&serialized).unwrap();
    assert_eq!(val, deserialized);
}
```

Composite generators can feed earlier draws into later ones — for example, only generating a `driving_license` field when `age >= 18`.

## Available generators

| Generator | Produces | Constraints |
|-----------|----------|-------------|
| `integers::<T>()` | Any integer type | `.min_value(n)`, `.max_value(n)` |
| `floats::<T>()` | f32, f64 | `.allow_nan(bool)`, `.allow_infinity(bool)` |
| `text()` | String | — |
| `binary()` | `Vec<u8>` | — |
| `booleans()` | bool | — |
| `vecs(gen)` | `Vec<T>` | `.min_size(n)`, `.max_size(n)` |
| `hashsets(gen)` | `HashSet<T>` | `.min_size(n)`, `.max_size(n)` |
| `hashmaps(k, v)` | `HashMap<K,V>` | `.min_size(n)`, `.max_size(n)` |
| `arrays::<N>(gen)` | `[T; N]` | — |
| `optional(gen)` | `Option<T>` | — |
| `one_of(gens)` | Union of generators | — |
| `sampled_from(slice)` | Element from a slice | — |
| `just(value)` | Constant value | — |
| `from_regex(pat)` | Strings matching a regex | — |
| `emails()` | Email addresses | — |
| `urls()` | URLs | — |
| `dates()` | Dates | — |
| `datetimes()` | DateTimes | — |

## Patterns

- Roundtrip serialization for every type the library handles.
- All integer widths (i8 through u64) roundtrip without truncation.
- Optional fields with `optional(gen)` cover both `Some` and `None` paths.
- Collections with `vecs(gen).min_size(0).max_size(10)` exercise empty and populated cases.
- Enum variants with `one_of![gen1, gen2, ...]` cover each arm.
- Nested structs via composite generators at multiple depths to catch recursive serialization bugs.

## Debugging

Use `tc.note()` to attach debug info that only appears when replaying the minimal failing example:

```rust
#[hegel::test]
fn some_property(tc: TestCase) {
    let x = tc.draw(integers::<i32>());
    let y = tc.draw(integers::<i32>());
    tc.note(&format!("x + y = {}", x + y));
    assert_eq!(x + y, y + x);
}
```

## Adjusting test cases

Default is 100 iterations. Override with the `test_cases` attribute:

```rust
#[hegel::test(test_cases = 500)]
fn thorough_check(tc: TestCase) {
    // ...
}
```
