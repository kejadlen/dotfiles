---
name: ruby-style
description: Use when writing, reviewing, or refactoring Ruby code — covers personal style preferences and conventions
---

# Ruby style

These are personal defaults. When a project has its own style guide,
RuboCop config, or established conventions, follow those instead.

## Hash and array access

Prefer `.fetch` over `[]` for hash and array access. `.fetch` raises
a `KeyError` or `IndexError` on missing keys, making bugs visible
immediately instead of propagating `nil` through the code.

```ruby
# good
config.fetch(:timeout)
config.fetch(:timeout, 30)
config.fetch(:timeout) { expensive_default }

# bad — silent nil on typos or missing keys
config[:timeout]
```

Use `[]` only when `nil` is a valid, expected result and you're
handling it intentionally.

## Block composition

Chain `.with_index` and `.with_object` onto the base enumerator
instead of using combined methods. This keeps each concern separate
and composes naturally with any iterator.

```ruby
# good — compose onto the base enumerator
array.each.with_index { |item, i| ... }
array.map.with_index { |item, i| ... }
array.flat_map.with_index { |item, i| ... }
array.each.with_object([]) { |item, acc| ... }
hash.each { |key, value| ... }

# bad — specialized methods
array.each_with_index { |item, i| ... }
array.each_with_object([]) { |item, acc| ... }
hash.each_value { |value| ... }
hash.each_key { |key| ... }
```

## Blocks

Use [Weirich-style](https://www.youtube.com/watch?v=KDTRsJCOPyI)
blocks: `{ }` when the block returns a meaningful value, `do...end`
when it's executed for side effects.

```ruby
# good — value-returning
names = items.map { |item| item.name }
config = defaults.merge(overrides) { |_key, old, new| new || old }

# good — side effects
items.each do |item|
  process(item)
  log(item)
end

Pathname.new(path).open do |f|
  f.write(data)
end

# bad — side effects with braces
items.each { |item| process(item) }

# bad — value-returning with do...end
names = items.map do |item| item.name end
```

## File and path operations

Prefer `Pathname` over `File` for path manipulation. `Pathname` is
object-oriented, composable, and works well with the rest of the
stdlib.

```ruby
# good
path = Pathname.new("/app/config/database.yml")
path.dirname
path.extname
path / ".." / "secrets.yml"

# bad — procedural and harder to chain
File.dirname("/app/config/database.yml")
File.extname("/app/config/database.yml")
File.expand_path("../secrets.yml", "/app/config/database.yml")
```

Use `File` only for the operations that don't have a `Pathname`
equivalent (`File.read`, `File.write`, `File.open` with a block).

## Building hashes

Prefer `.to_h` with a block over `.each_with_object` or manual
hash construction.

```ruby
# good
users.to_h { |user| [user.id, user.name] }

# bad
users.each_with_object({}) { |user, hash| hash[user.id] = user.name }
Hash[users.map { |user| [user.id, user.name] }]
```

## Frozen string literals

Prefer enabling frozen string literals process-wide with
`RUBYOPT=--enable-frozen-string-literal` (set it in your shell profile,
`.env`, or CI) over adding a `# frozen_string_literal: true` magic
comment to every file. One environment setting covers the whole project
instead of a comment that has to be added to — and kept on — each new
file.

```bash
# good — one setting for the whole project
export RUBYOPT=--enable-frozen-string-literal

# bad — per-file ceremony repeated in every file
# frozen_string_literal: true
```

The flag applies to every file that lacks its own magic comment, so a
file can still opt out with an explicit `# frozen_string_literal: false`
when it genuinely needs mutable string literals.

Don't fight an existing convention. If a project already relies on the
magic comment — RuboCop's `Style/FrozenStringLiteralComment` is enabled,
or the files already carry it — keep adding the comment so the codebase
stays consistent.

## Binstubs

Prefer binstubs over `bundle exec`. Run `bundle binstubs --all` to
generate them, then use `bin/rake`, `bin/rails`, etc. directly.

```bash
bundle binstubs --all
bin/rake test
```

## Testing

Prefer Minitest over RSpec. Use `Minitest::Test` with plain `def
test_*` methods — no spec DSL.

```ruby
class MyClassTest < Minitest::Test
  def test_it_works
    assert_equal "expected", MyClass.new.call
  end
end
```

---

*This is a self-improving skill — see the `self-improving-skills` skill.*
