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

# bad — silent nil on typos or missing keys
config[:timeout]
```

Use `[]` only when `nil` is a valid, expected result and you're
handling it intentionally.

## Safe navigation

Reach for `&.` only where `nil` is a legitimate value you handle right
there. Used defensively, it turns a nil receiver into a nil result and
passes the problem to the next line — the same silent propagation
`.fetch` exists to prevent.

```ruby
# good — an empty queue is expected, and the nil is resolved here
label = queue.shift&.strip || "(idle)"

# bad — hides which of the three was missing, and why
user&.profile&.avatar&.url
```

When a value shouldn't be nil, let it raise; the backtrace points at
the real bug. When it should, handle it once — a guard clause, a
default, or a null object — rather than threading `&.` through every
call downstream.

```ruby
# good
return unless user

user.profile.avatar.url
```

Two behaviors make long chains worse than they look. Only the link
`&.` attaches to is guarded, so `a&.b.c` still raises when `a` is nil.
And a predicate answers `nil` instead of `false`, so `x&.empty?` is
neither true nor false — `unless x&.empty?` runs its body when `x` is
nil.

## Enumerable methods

Chain `.with_index` and `.with_object` onto the base enumerator
instead of using combined methods. This keeps each concern separate
and composes naturally with any iterator.

```ruby
# good — compose onto the base enumerator
array.each.with_index { |item, i| ... }
array.each.with_object([]) { |item, acc| ... }
hash.each { |key, value| ... }

# bad — specialized methods
array.each_with_index { |item, i| ... }
array.each_with_object([]) { |item, acc| ... }
```

The same goes for the specialized `each_*` readers (`each_value`,
`each_key`) and the string readers (`str.chars.map`, not
`str.each_char.map`) — take the plain method and chain from there.
The exception is hot paths on large strings, where the lazy
`Enumerator` from `each_char` and friends beats building the whole
array up front.

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
path / ".." / "secrets.yml"

# bad — procedural and harder to chain
File.dirname("/app/config/database.yml")
File.expand_path("../secrets.yml", "/app/config/database.yml")
```

Use `File` for plain IO when `Pathname` adds nothing.

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

## Memoization

Compute values in `initialize` and expose them with `attr_reader`. An
object built that way is complete the moment it exists, and its state
doesn't depend on which methods have been called yet.

```ruby
# good
class Report
  def initialize(rows)
    @rows = rows
    @total = rows.sum(&:amount)
  end

  attr_reader :total
end

# bad — state accumulates as methods get called
def total
  @total ||= @rows.sum(&:amount)
end
```

Lazy caching earns its place when the work is expensive and often
skipped — reading a file, calling out over the network. Guard it with
`defined?`, which asks whether the variable was assigned rather than
what it holds.

```ruby
# good
def manifest
  return @manifest if defined?(@manifest)

  @manifest = parse(path.read)
end
```

Never memoize with `||=`. It rewrites to `@x || @x = ...`, so a `nil`
or `false` result reads as "not computed yet" and reruns the work on
every call — the expensive case the cache existed to prevent.

## Parsing

Reach for `StringScanner` when the input has structure — anything you'd
otherwise pick apart with a chain of `split` or an offset you increment
by hand. The scanner
holds the cursor, anchors every match at it, and `eos?` says when the
input is spent.

```ruby
require "strscan"

# good
scanner = StringScanner.new(input)
key = scanner.scan(/\w+/)
scanner.skip(/\s*=\s*/)
value = scanner.scan(/[^;]+/)
raise ArgumentError, "unparsed: #{scanner.rest}" unless scanner.eos?

# bad — quietly accepts anything with an "=" in it
key, value = input.split("=", 2)
```

`scan` and `skip` return `nil` without moving the cursor when the
pattern doesn't match, so treat that `nil` as the parse error the way
you'd treat a missing key from `.fetch` — raise on it instead of
letting it flow onward.

Skip the scanner when there's nothing to track: one `match` against a
whole string, or a genuinely flat delimited line. And for a format that
already has a parser — JSON, YAML, CSV — use that parser.

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
