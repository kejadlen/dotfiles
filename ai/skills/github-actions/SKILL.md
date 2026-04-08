---
name: github-actions
description: Use when writing, reviewing, or debugging GitHub Actions workflows — covers security hardening, concurrency, job structure, permissions, and common patterns
---

# GitHub Actions

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Security

**Default-deny permissions.** Set `permissions: {}` at the workflow level,
then grant the minimum each job needs. **Every permission line gets a
comment explaining why** — no bare permissions:

```yaml
permissions: {}

jobs:
  test:
    permissions:
      contents: read  # checkout
      packages: write # push container image to GHCR
```

**Pin actions to full commit SHAs**, not tags. Tags are mutable — a
compromised action can be re-tagged. Add a version comment for humans:

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
```

**Disable credential persistence** on checkout to prevent tokens from
leaking to later steps:

```yaml
- uses: actions/checkout@<sha> # v6
  with:
    persist-credentials: false
```

This breaks `git push` — you can't push tags or commits from a step
that checked out without credentials. Use `gh release create --target
"${GITHUB_SHA}"` to create both the tag and release via the API
instead of `git tag` + `git push`.

**Indirect environment variable expansion.** Never interpolate
expressions directly in `run:` scripts — an attacker-controlled value
(branch name, PR title) can inject shell commands. Assign expressions to
env vars first:

```yaml
# wrong — injectable
- run: echo "${{ github.event.pull_request.title }}"

# correct — safe expansion
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "$PR_TITLE"
```

Name the env var after the expression path, uppercased with underscores:
`${{ steps.meta.outputs.version }}` → `STEPS_META_OUTPUTS_VERSION`,
`${{ needs.build.outputs.image }}` → `NEEDS_BUILD_OUTPUTS_IMAGE`.

## Concurrency

**Cancel in-progress PR runs.** Use the workflow name and ref as the
concurrency key, and only cancel for PRs (not pushes to main):

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

**Serialize deploys.** Use a fixed group name with `cancel-in-progress:
true` so only the latest deploy runs:

```yaml
concurrency:
  group: fly-deploy
  cancel-in-progress: true
```

## Job structure

**Separate test, build, and deploy.** Use `needs:` to express
dependencies and `if:` to gate jobs on context:

```yaml
jobs:
  test:
    # runs on all pushes and PRs
  build:
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  deploy:
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

**Pass data between jobs with outputs.** Declare outputs in the
producing job and reference them downstream. Assign the output to an
env var rather than interpolating in `run:`:

```yaml
build:
  outputs:
    image: ghcr.io/${{ github.repository }}:${{ steps.meta.outputs.version }}

deploy:
  needs: build
  steps:
    - run: flyctl deploy --image ${IMAGE}
      env:
        IMAGE: ${{ needs.build.outputs.image }}
```

## Environments

Use GitHub environments for deploy protection rules. For PR previews,
key the name on the PR number:

```yaml
preview:
  environment:
    name: pr-${{ github.event.number }}
    url: ${{ steps.deploy.outputs.url }}
```

## Zizmor

Static analysis for GitHub Actions. Catches template injection,
excessive permissions, unpinned actions, credential leaks, and more.
Run `zizmor --help` for full options.

**Always add a zizmor audit job to CI.** Every repo with GitHub Actions
workflows should include one:

```yaml
zizmor:
  runs-on: ubuntu-latest
  permissions:
    contents: read         # checkout
    security-events: write # upload SARIF to code scanning
  steps:
    - uses: actions/checkout@<sha> # v6
      with:
        persist-credentials: false
    - uses: zizmorcore/zizmor-action@<sha>
```

Local usage:

```bash
zizmor .                          # audit current repo
zizmor .github/workflows/ci.yml   # single file
zizmor --fix .                    # auto-fix safe findings
zizmor --pedantic .               # include code smells
```

Configure with `zizmor.yml` in repo root or `.github/`. Ignore inline
with a justification after `--`:

```yaml
on:
  workflow_run: # zizmor: ignore[dangerous-triggers] -- scoped to main branch, checks conclusion
```

## Renovate integration

Pin action SHAs and let Renovate update them. The `github-actions`
manager detects `uses:` lines automatically — no extra config needed.

## Quick reference

| What | How |
|---|---|
| Set step output | `echo "key=value" >> "$GITHUB_OUTPUT"` |
| Set env for later steps | `echo "KEY=value" >> "$GITHUB_ENV"` |
| Conditional job | `if: github.ref == 'refs/heads/main'` |
| Conditional step | `if: github.event.action != 'closed'` |
| Job dependency | `needs: [test, lint]` |
| Job output | `outputs: { version: ${{ steps.x.outputs.version }} }` |
| Consume job output | `${{ needs.build.outputs.version }}` |
| Cancel previous runs | `cancel-in-progress: true` in `concurrency:` |
| Required permissions | `permissions:` block per job |
