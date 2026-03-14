---
name: ruby-typing
description: Use when adding type annotations to Ruby code, running Steep or rbs-inline, or troubleshooting type errors in Ruby projects
---

# Ruby Type Checking with Steep and rbs-inline

## Workflow

1. Add `# rbs_inline: enabled` at the top of the file
2. Annotate methods and Data.define fields with `#:` comments
3. Run `rbs-inline --output lib/` to generate `.rbs` files under `sig/generated/`
4. Run `steep check` to verify

## rbs-inline Annotations

Method signatures use `#:` on the line before `def`:

```ruby
#: (String, Integer) -> String
def repeat(str, count)
  str * count
end

#: () -> void
def reset!
  @count = 0
end
```

Data.define fields are annotated inline per member:

```ruby
MyConfig = Data.define(
  :name,     #: String
  :timeout,  #: Integer?
)
```

This generates typed `attr_reader`, `self.new`, and `members` in the RBS output.

## Known Limitations

rbs-inline ignores methods defined inside a `Data.define` block. Reopen the class in a separate body:

```ruby
# Won't work — rbs-inline can't see parse:
MyData = Data.define(:name) do
  def self.parse(value) = new(name: value)
end

# Works — reopen the class:
MyData = Data.define(:name)
class MyData
  #: (String) -> MyData
  def self.parse(value) = new(name: value)
end
```

`String#split` returns `Array[String]`, so destructuring gives `String?` for each element. Use a tuple assertion to tell Steep the exact shape:

```ruby
login, name = value.split(":", 2) #: [String, String?]
```

## Steep Tips

`Hash[String, String]` for env-like hashes. Use `String?` values only if the hash actually contains nils — `ENV#fetch` with a block returns `String`, not `String?`.

Steep differentiates `instance` from the class name in return types. `Data.define` constructors return `instance`; your own class methods should return the class name (`MyData`, not `instance`).

## Quick Reference

| Annotation | Meaning |
|---|---|
| `#: (String) -> Integer` | Method type (before def) |
| `#: String` | Field/attr type (inline after member) |
| `#: [String, String?]` | Tuple type assertion (inline after expression) |
| `# @rbs skip` | Exclude from RBS generation |
| `# @rbs override` | Method overrides parent |
| `# rbs_inline: enabled` | Opt file into RBS generation |
