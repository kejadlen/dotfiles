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

## Enumerable methods

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

The same goes for the specialized `each_*` readers — take the plain
method and chain from there. The exception is hot paths on large
strings, where the lazy `Enumerator` from `each_char` and friends beats
building the whole array up front.

```ruby
# good
str.chars.map { |char| char.ord }
str.lines.grep(/^#/)

# bad
str.each_char.map { |char| char.ord }
str.each_line.grep(/^#/)
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

# bad — side effects with braces
items.each { |item| process(item) }

# bad — value-returning with do...end
names = items.map do |item| item.name end
```

## Implicit block parameter

Use `it` when the receiver makes the subject obvious. Name the parameter
when the block runs long enough that the reader loses track of what `it`
is, or when the name carries something the receiver doesn't. Prefer `it`
over `_1` — it reads as English.

```ruby
# good
users.map { it.name }
paths.select { it.exist? }

# bad — a name that adds nothing
users.map { |user| user.name }
```

`it` only applies to a block that declares no parameters, so a block
that needs two still names them: `hash.each { |key, value| ... }`. A
local variable named `it` in scope shadows the implicit parameter
silently, so watch for one.

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

## Trailing commas

Use a trailing comma on the last element of a multiline literal or
argument list, so adding an element touches one line instead of two.

```ruby
# good
COLORS = [
  "red",
  "green",
]

client.call(
  path,
  timeout: 30,
)

# bad — a single-line literal gains nothing from it
COLORS = ["red", "green",]
```

Ruby rejects a trailing comma in a method definition's parameter list,
so a multiline `def` is the one exception.

Never add one to block parameters — it isn't cosmetic there. `|a,|`
destructures the first element out of an array, where `|a|` binds the
whole array.

```ruby
[[1, 2, 3]].map { |a| a }   # => [[1, 2, 3]]
[[1, 2, 3]].map { |a,| a }  # => [1]
```

## Frozen string literals

Enable frozen string literals process-wide with
`RUBYOPT=--enable-frozen-string-literal` (set it in your shell profile,
`.env`, or CI). Don't add `# frozen_string_literal:` magic comments to
files — in either direction — one environment setting covers the whole
project.

```bash
export RUBYOPT=--enable-frozen-string-literal
```

Literals in files with no magic comment are *chilled*: mutating one
warns instead of raising. Run with `RUBYOPT=-W:deprecated` to find them,
then `.dup` each one.

## Requires

Put `require` calls at the top of the file. Defer one inside a method
or conditional only with an actual reason — cutting boot time for a
rarely used, expensive dependency being the usual one.

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
