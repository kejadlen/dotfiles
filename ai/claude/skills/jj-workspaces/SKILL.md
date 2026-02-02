---
name: jj-workspaces
description: Use when needing isolated workspace for experiments, parallel development, or subagent coordination - covers solo experimentation and multi-agent workflows with jj workspaces
---

# jj Workspaces

## Overview

Create isolated jj workspaces for experimentation, parallel development, and subagent coordination. All workspaces share repository history, enabling seamless switching and comparison.

**Core principle:** Isolation by design. Each workspace operates independently with zero risk of interference.

**Important:** Run `jj` (or `jj status`) periodically in each workspace. jj only snapshots the working copy when you run a command—it doesn't watch for file changes. Running `jj` ensures it sees your edits.

## When to Use

**Triggers:**
- Testing breaking changes or refactors that might not work
- Comparing multiple implementation approaches
- Running long-running operations without blocking other work
- Dispatching subagents to implement features in parallel
- Need isolated development for any reason

## Workspace Location

**Always use `work/` directory** (relative to repo root).

**Naming:** Use lowercase, descriptive names. Include story/ticket ID as prefix if work is tracked (e.g., `abc-123-auth-feature`, `async-refactor`, `api-v2`).

## Creating a Workspace

```bash
# 1. Ensure work directory exists and create workspace
mkdir -p work
jj workspace add --name=<name> work/<name>

# Or from specific revision
jj workspace add --name=<name> -r <rev> work/<name>

# 2. Place in DAG - if megamerge (mm) exists, insert between trunk and mm
jj rebase -r <name>@ -A 'trunk()' -B mm

# If no megamerge, just rebase onto trunk:
# jj rebase -r <name>@ -d 'trunk()'

# 3. Sync main workspace
jj workspace update-stale
```

**Result (with mm):** `trunk() → workspace change → mm`

## Solo Experiments

### Work and Evaluate

```bash
cd work/<name>
# Make changes, run tests, build
# Commits are isolated to this workspace
```

**If successful:** Merge back:
```bash
jj rebase -s <name>@ -d @
```

**If unsuccessful:** Forget and clean up:
```bash
jj workspace forget <name>
rm -rf work/<name>
```

### Parallel Experiments

Create multiple workspaces to compare approaches:

```bash
jj workspace add --name=approach-a work/approach-a
jj workspace add --name=approach-b work/approach-b
# Don't forget to place each in DAG if mm exists
```

Compare from main workspace:
```bash
jj log -r 'working_copies()'
jj diff -r approach-a@ -r approach-b@
```

## Subagent Coordination

For dispatching agents to work in parallel. **Execute setup BEFORE dispatching ANY agents.**

### Phase 1: Setup (Coordinator)

Create workspace(s) using the standard process above.

### Phase 2: Dispatch (Coordinator)

Use Task tool to dispatch in parallel. **Start agents in the workspace directory** using the Task tool's working directory or by instructing the agent to `cd` first. Each agent gets:
- Task specification
- Workspace path (exactly one) - agent starts here
- Verification commands
- Success criteria

### Phase 3: Execution (Agent)

**Agent MUST:**
1. `cd` into workspace directory first—all work happens FROM that directory
2. Make file edits to implement task
3. Run verification (tests, type checks)
4. Split changes to parent: `jj split -m '<description>' .` (selects all files, creates parent commit with changes, leaves working copy empty)
5. Report: what changed, verification output, change ID

**Why `jj split` instead of `jj commit`:** Splitting moves changes into a new parent commit while leaving the workspace's working copy commit empty. This keeps the workspace commit as the megamerge parent, maintaining the DAG structure. The `-m` flag provides the description inline, avoiding interactive prompts.

**FORBIDDEN for agents:**
- `jj workspace` commands
- `jj git push`
- `jj rebase`
- Any work outside assigned workspace

### Phase 4: Review (Coordinator)

```bash
jj workspace update-stale  # Sync to see agent's changes
jj diff -r <name>@         # Review work
jj status                  # Check conflicts, resolve if needed
```

### Phase 5: Cleanup

```bash
jj workspace forget <name>
rm -rf work/<name>
```

## Commands Reference

```bash
# Create workspace (ensure work/ exists first)
mkdir -p work && jj workspace add --name=<name> work/<name>
jj workspace add --name=<name> -r <rev> work/<name>

# List workspaces
jj workspace list

# Forget workspace (keeps commits)
jj workspace forget <name>

# View workspace commits
jj log -r 'working_copies()'

# Reference workspace's current commit
<name>@

# Sync after external workspace changes
jj workspace update-stale
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Working from wrong directory | Agent must `cd` into workspace directory first—all commands run FROM there |
| Skipping DAG placement | Must run `jj rebase` to place in DAG (with `-B mm` if megamerge exists) |
| Agent skipping split | Agent must run `jj split -m '<description>' .` to finalize changes |
| Skipping `jj workspace update-stale` | Run in main workspace after workspace operations |
| Creating workspaces during dispatch | Create ALL workspaces BEFORE dispatch |
| Agent touching other workspaces | Agents work ONLY in assigned path |
| Forgetting cleanup | Remove directories after forgetting workspace |
| jj not seeing file changes | Run `jj` or `jj status` periodically—jj only snapshots on command execution |

## Red Flags

| Thought | Reality |
|---------|---------|
| "I can work from the main workspace" | Must `cd` into workspace directory—jj context depends on cwd |
| "I'll skip DAG placement" | Must place in DAG for clean integration |
| "Agent doesn't need to split" | Agent must run `jj split -m '<description>' .` to finalize changes |
| "I'll create workspaces during dispatch" | Create ALL workspaces first |
| "Custom directory is fine" | Always use `work/` directory |
| "This is overkill for one agent" | Single-agent workflow maintains consistency |

## Failure Recovery

**Agent timeout:** Retry with fresh context. Work in workspace is preserved.

**Verification fails:** Agent reports failure. Coordinator decides: retry, fix, or revert.

**Conflicts after sync:** Expected. Coordinator resolves via `jj resolve`.

All failures are contained and recoverable.

## References

- [jj-workspace-experiments](https://github.com/thoughtpolice/a/blob/canon/.claude/skills/jj-workspace-experiments/SKILL.md) - Original source for workspace patterns
