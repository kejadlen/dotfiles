---
name: dependency-management
description: Use when adding, updating, or reviewing dependency declarations — covers manifest vs lock file conventions, version specifiers, and when to pin
---

# Dependency management

## Manifests describe ranges, lock files pin exact versions

The manifest (e.g., `package.json`, `Gemfile`, `Cargo.toml`, `pyproject.toml`,
`go.mod`) declares what you need and the acceptable version range. The lock
file (e.g., `package-lock.json`, `Gemfile.lock`, `Cargo.lock`,
`poetry.lock`, `go.sum`) records the exact resolved versions.

Keep manifests unpinned. Use version ranges instead of exact versions:

```json
// package.json — good
"dependencies": {
  "lodash": "^4.17.0"
}

// package.json — bad (this is what lock files are for)
"dependencies": {
  "lodash": "4.17.21"
}
```

```ruby
# Gemfile — good
gem "rails", "~> 7.0"

# Gemfile — bad
gem "rails", "7.0.4.1"
```

```toml
# Cargo.toml — good
[dependencies]
serde = "1.0"

# Cargo.toml — bad
serde = "=1.0.195"
```

## Rationale

Pinning in the manifest defeats the purpose of having a lock file:

- Two files doing the same job creates drift — one gets updated, the
  other doesn't.
- Ranges give you controlled flexibility: patch and minor updates flow
  in when you run `update`, without manual version bumps in the manifest.
- Lock files guarantee reproducibility. That's their job. Let them do it.
- Pinned manifests make `dependency update` PRs noisy — every version
  bump requires a manifest edit instead of just a lock file change.

## When to pin

The only acceptable reason to pin in the manifest is when a specific
version has a known incompatibility and you need to exclude it:

```ruby
# Acceptable — excluding a broken version
gem "nokogiri", "~> 1.15", "!= 1.15.3"
```

```toml
# Acceptable — known regression in a specific version
[dependencies]
reqwest = "0.11, !=0.11.18"
```

Prefer excluding bad versions over pinning to one good version. The
range stays open for future fixes while protecting against the known
problem.

## Lock file hygiene

- Commit lock files to version control. They are the source of truth for
  reproducible builds.
- Don't manually edit lock files. Use the package manager's update
  commands.
- When reviewing dependency update PRs, verify the lock file changed and
  the manifest didn't (unless the change adds or removes a dependency).

---

*This is a self-improving skill — see the `self-improving-skills` skill.*
