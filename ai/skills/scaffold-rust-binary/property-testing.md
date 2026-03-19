# Property Testing

`tests/property.rs` uses proptest to verify invariants across randomly generated inputs. The most common pattern is roundtrip testing: serialize a value, deserialize it, and confirm equality.

Define reusable strategies for domain types, then compose them:

```rust
use proptest::prelude::*;

/// Strategy for strings safe to roundtrip through your format.
fn safe_string() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9 _.,:;!?-]{0,64}"
}

/// Strategy for finite f64 (excludes NaN and infinity).
fn finite_f64() -> impl Strategy<Value = f64> {
    prop::num::f64::ANY.prop_filter("finite floats only", |f| f.is_finite())
}

fn my_struct_strategy() -> impl Strategy<Value = MyStruct> {
    (safe_string(), any::<i32>(), any::<bool>(), finite_f64()).prop_map(
        |(name, count, enabled, ratio)| MyStruct { name, count, enabled, ratio },
    )
}

proptest! {
    #[test]
    fn roundtrip(val in my_struct_strategy()) {
        let serialized = my_crate::serialize(&val).unwrap();
        let deserialized: MyStruct = my_crate::deserialize(&serialized).unwrap();
        prop_assert_eq!(val, deserialized);
    }
}
```

## Patterns

- Roundtrip serialization for every type the library handles
- All integer widths (i8 through u64) roundtrip without truncation
- Optional fields with `prop::option::of(...)` cover both `Some` and `None` paths
- Collections with `prop::collection::vec(strategy, 0..10)` exercise empty and populated cases
- Enum variants with `prop_oneof![...]` cover each arm
- Nested structs at multiple depths to catch recursive serialization bugs

## Regression Files

Proptest regression files (`*.proptest-regressions`) record failing seeds. Commit them so CI reproduces past failures.
