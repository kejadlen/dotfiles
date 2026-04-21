---
name: actions-workflows
description: Use when writing, reviewing, or debugging GitHub Actions or Gitea Actions workflows — covers security hardening, concurrency, job structure, permissions, engine differences, and mirror patterns
---

# Actions workflows

*This is a self-improving skill — see the `self-improving-skills` skill.*

Gitea Actions is a GitHub Actions-compatible engine. Same YAML, same
`${{ github.* }}` contexts, same `$GITHUB_OUTPUT`/`$GITHUB_ENV`
conventions, same public action marketplace. Workflows live in
`.github/workflows/` or `.gitea/workflows/`; every pattern in this
skill works in both unless a section says otherwise.

Gitea's self-hosted runners are minimal — don't assume `rustup`,
`gh`, `just`, or similar tools are preinstalled. Install what you need
inline or build a custom runner image.

## The mirror pattern

Self-host the canonical repo on Gitea, mirror to GitHub to offload
releases. The goal is to keep the code on infrastructure you control
while still getting the GitHub ecosystem for anything release-facing:
hosted cross-platform runners, dotslash publishing, GHCR, and the
download reach that comes with GitHub Releases. The mirror is
read-only — nobody commits to it.

The split:

- Gitea runs day-to-day CI (tests, lint, coverage) and the tagging
  workflow. This is where you push.
- GitHub runs on `push: tags: [v*]` to build release artifacts and
  publish them. The mirror is the only writer.

Ranger uses this pattern: Gitea's `release.yml` pushes a
`v<calver>+<sha>` tag, the mirror propagates the tag to GitHub, and
GitHub's `release.yml` picks it up and builds macOS and Linux
binaries. The GitHub side can use triggers that would be risky on a
repo accepting fork PRs, because the mirror doesn't accept them.

When splitting, annotate the GitHub workflow's trigger so zizmor
understands the context:

```yaml
on: # zizmor: ignore[dangerous-triggers] -- only triggers on tag pushes from Gitea mirror; no fork PR risk.
  push:
    tags: [v*]
```

## Security

Default-deny permissions. Set `permissions: {}` at the workflow level,
then grant the minimum each job needs. Every permission line gets a
comment explaining why — no bare permissions:

```yaml
permissions: {}

jobs:
  test:
    permissions:
      contents: read  # checkout.
      packages: write # push container image to GHCR.
```

Pin actions to full commit SHAs, not tags. Tags are mutable — a
compromised action can be re-tagged. Add a version comment for humans:

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
```

This applies on Gitea too, even though actions are proxied through
the Gitea instance. The upstream repo is still the source of truth.

Disable credential persistence on checkout to prevent tokens from
leaking to later steps:

```yaml
- uses: actions/checkout@<sha> # v6
  with:
    persist-credentials: false
```

This breaks `git push` from later steps. On GitHub, use `gh release
create --target "${GITHUB_SHA}"` to create the tag and release via the
API. On Gitea, use `tea releases create` or a direct API call with a
scoped token. If you truly need `git push` (for example, to push a
tag), scope the credentials to the single step that needs them —
don't leave them persistent for the whole job.

Indirect environment variable expansion. Never interpolate expressions
directly in `run:` scripts — an attacker-controlled value (branch
name, PR title, issue body) can inject shell commands. Assign
expressions to env vars first:

```yaml
# wrong — injectable.
- run: echo "${{ github.event.pull_request.title }}"

# correct — safe expansion.
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "$PR_TITLE"
```

Name the env var after the expression path, uppercased with
underscores: `${{ steps.meta.outputs.version }}` →
`STEPS_META_OUTPUTS_VERSION`, `${{ needs.build.outputs.image }}` →
`NEEDS_BUILD_OUTPUTS_IMAGE`.

## Concurrency

Cancel in-progress PR runs. Use the workflow name and ref as the
concurrency key, and only cancel for PRs (not pushes to main):

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

Serialize deploys. Use a fixed group name with `cancel-in-progress:
true` so only the latest deploy runs:

```yaml
concurrency:
  group: fly-deploy
  cancel-in-progress: true
```

## Job structure

Separate test, build, and deploy. Use `needs:` to express dependencies
and `if:` to gate jobs on context:

```yaml
jobs:
  test:
    # runs on all pushes and PRs.
  build:
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  deploy:
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

Pass data between jobs with outputs. Declare outputs in the producing
job and reference them downstream. Assign the output to an env var
rather than interpolating in `run:`:

```yaml
build:
  outputs:
    image: ghcr.io/${{ github.repository }}:${{ steps.meta.outputs.version }}

deploy:
  needs: build
  steps:
    - run: flyctl deploy --image "$IMAGE"
      env:
        IMAGE: ${{ needs.build.outputs.image }}
```

## Environments (GitHub only)

Use GitHub environments for deploy protection rules and
environment-scoped secrets. For PR previews, key the name on the PR
number:

```yaml
preview:
  environment:
    name: pr-${{ github.event.number }}
    url: ${{ steps.deploy.outputs.url }}
```

Gitea doesn't have a fully equivalent environments feature. For Gitea,
use repo-level or org-level secrets and gate sensitive jobs with `if:`
conditions instead.

## Zizmor

Static analysis for Actions workflows. Catches template injection,
excessive permissions, unpinned actions, credential leaks, and more.
Run `zizmor --help` for full options. Zizmor treats Gitea and GitHub
workflows the same way — point it at both directories.

Always add a zizmor audit job to CI. For a repo with both directories,
pass them explicitly:

```yaml
zizmor:
  runs-on: ubuntu-latest
  permissions:
    contents: read         # checkout.
    security-events: write # upload SARIF to code scanning (GitHub only — drop on Gitea).
  steps:
    - uses: actions/checkout@<sha> # v6
      with:
        persist-credentials: false
    - uses: zizmorcore/zizmor-action@<sha>
      with:
        inputs: .gitea/workflows/* .github  # audit both sets.
        advanced-security: false             # set true on GitHub for SARIF upload.
        annotations: true
```

On Gitea, drop `security-events: write` and the SARIF upload — leave
`annotations: true` so findings show up in the run log.

Local usage. `zizmor .` only discovers `.github/workflows/` — pass
`.gitea/workflows/*` explicitly on a dual-engine repo, or it silently
skips every Gitea workflow:

```bash
zizmor .gitea/workflows/* .github   # audit both directories.
zizmor .gitea/workflows/ci.yml      # single file.
zizmor --fix .gitea/workflows/* .github
zizmor --pedantic .gitea/workflows/* .github
```

Configure with `zizmor.yml` in the repo root, `.github/`, or
`.gitea/`. Ignore inline with a justification after `--`:

```yaml
on:
  workflow_run: # zizmor: ignore[dangerous-triggers] -- scoped to main branch, checks conclusion.
```

## Renovate integration

On GitHub, pin action SHAs and let Renovate update them. The
`github-actions` manager detects `uses:` lines automatically — no
extra config needed.

On Gitea, Renovate works but needs the workflow paths configured —
its `github-actions` manager looks at `.github/workflows/` by default.
Extend `fileMatch` in `renovate.json`:

```json
{
  "github-actions": {
    "fileMatch": ["(^|/)\\.gitea/workflows/[^/]+\\.ya?ml$"]
  }
}
```

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
| GitHub CLI in a step | `env: { GH_TOKEN: ${{ github.token }} }` |
| Gitea CLI in a step | `env: { TEA_TOKEN: ${{ secrets.TEA_TOKEN }} }` |
