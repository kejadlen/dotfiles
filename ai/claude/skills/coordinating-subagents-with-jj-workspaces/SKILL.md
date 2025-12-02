---
name: coordinating-subagents-with-jj-workspaces
description: Use when dispatching subagents to implement features on a jj repository (on request) - provides explicit setup, isolation enforcement, conflict resolution, and mandatory verification to eliminate ambiguity and enable safe parallel development
---

# Coordinating Subagents with jj Workspaces

## Overview

Enable safe parallel feature development by dispatching independent subagents to isolated jj workspaces, with explicit isolation enforcement, conflict detection, and mandatory verification gates.

**Core principle:** Isolation by design. Each agent works independently in an isolated workspace, creating revisions on a clean slate, with zero risk of interfering with other agents. Verification and conflict resolution happen centrally after all agents complete.

## When to Use

**Triggers:**
- You explicitly request this workflow for subagent coordination
- Single-agent task needing isolated development (simplest case)
- Multiple independent features ready for parallel development
- Need to coordinate work across several subagents simultaneously
- Want unified conflict detection and resolution

**When NOT to use:**
- Tasks have dependencies (use sequential development)
- Features require constant coordination (use pair programming)

## The Workflow Checklist

**CRITICAL: Create TodoWrite todos for EACH step below. This workflow has sequential gates.**

### Phase 1: Setup (Coordinator)

- [ ] Create workspace: `jj workspace add ~/src/workspaces/<name>`
- [ ] Place in DAG: `jj rebase -r <name>@ -A 'trunk()' -B mm`
- [ ] Sync main workspace: `jj workspace update-stale`
- [ ] **BLOCKER:** Phase 1 MUST complete before dispatch.

### Phase 2: Dispatch (Coordinator)

- [ ] Dispatch subagent with: task spec + workspace path + verification commands
- [ ] For multiple agents: dispatch in parallel with Task tool

### Phase 3: Execution (Agent)

- [ ] Agent makes file edits in workspace
- [ ] Agent runs verification (tests, type checks)
- [ ] Agent describes change: `jj describe -m "..."`
- [ ] Agent creates new change: `jj new -A @ -B mm`
- [ ] Agent reports completion with results and change ID

### Phase 4: Review (Coordinator)

- [ ] Sync: `jj workspace update-stale`
- [ ] Review: `jj diff -r <workspace>@`
- [ ] Check conflicts: `jj status`
- [ ] Resolve conflicts if needed

### Phase 5: Cleanup (Coordinator)

- [ ] Delete workspace: `jj workspace forget <name>`
- [ ] Remove directory: `rm -rf ~/src/workspaces/<name>`
- [ ] Work remains in jj repository history

## Setup: Creating Workspaces and DAG Placement

**Before dispatching ANY agents, execute this setup:**

### Step 1: Create the Workspace

**MANDATORY location:** `~/src/workspaces/` - Fixed, standard location across all projects.

**Workspace naming:** `{jira-id-if-present}-{feature-name}` - Include JIRA ID as prefix ONLY if work is tracked in JIRA. Use LOWERCASE only.

```bash
# Create workspace (all lowercase)
jj workspace add ~/src/workspaces/proj-123-feature-name
```

### Step 2: Place Workspace in DAG (Critical)

**The workspace change MUST be inserted between trunk() and the megamerge (mm).** This ensures the work integrates cleanly into your development stack.

```bash
# Insert workspace change between trunk and megamerge
jj rebase -r <workspace-name>@ -A 'trunk()' -B mm
```

Example:
```bash
jj rebase -r proj-123-feature-name@ -A 'trunk()' -B mm
```

**Result:** `trunk() → workspace change → mm`

### Step 3: Sync Main Workspace

After setup in the workspace, sync the main workspace to see the new changes:

```bash
# In main workspace
jj workspace update-stale
```

This updates the main workspace's view of the DAG after changes made in other workspaces.

### Key Points

- Workspaces created BEFORE agents start (not during)
- DAG placement happens BEFORE dispatch
- Run `jj workspace update-stale` in main workspace after workspace operations

## Dispatching Agents

**Use the Task tool to dispatch in parallel. Example:**

```
Task 1: Dispatch auth agent to auth workspace
- Task: auth-feature
- Workspace path: ~/src/workspaces/proj-123-auth
- Requirements: Implement OAuth, create auth middleware, add login endpoints
- Verification: Run tests, confirm all pass
- Success criteria: OAuth flow works end-to-end

Task 2: Dispatch API agent to api workspace
- Task: api-endpoint
- Workspace path: ~/src/workspaces/api-endpoint
- [... similar structure ...]

Task 3: Dispatch DB agent to db workspace
- Task: db-migration
- Workspace path: ~/src/workspaces/db-migration
- [... similar structure ...]
```

**Critical enforcement:**
- Each agent gets EXACTLY ONE workspace path
- No agent can see other workspaces (isolation guarantee)
- Agents work in parallel (no waiting)
- Each agent must report verification status

## Agent Contract (What Agents Must Do)

**Each agent MUST:**
1. Work ONLY in their assigned workspace path
2. Make file edits to implement the task
3. Run verification steps (tests, type checks, etc.)
4. Describe the change: `jj describe -m "feat: ..."` (use describing-changes skill)
5. Create new change: `jj new -A @ -B mm`
6. Report results: what changed, verification output, final change ID
7. Make NO changes outside their workspace

**Agent workflow:**
1. Make file edits in workspace
2. Run verification commands
3. Describe changes with `jj describe -m "..."`
4. Create new change with `jj new -A @ -B mm`
5. Report completion with results and change ID

This inserts a new empty change between the completed work and the workspace's stable parent, ready for the next task.

**FORBIDDEN for agents:**
- `jj workspace` commands - breaks isolation
- `jj git push` - coordinator handles
- `jj rebase` - coordinator handles DAG operations
- Any work outside assigned workspace path

**If verification fails:**
- Agent reports what failed and why
- Agent attempts one retry OR hands off to coordinator

**Coordinator handles:**
- DAG operations (rebase, etc.)
- Code review of agent's changes via `jj diff`
- Conflict resolution after `jj workspace update-stale`
- Decision about failed verification
- Pushing to remote

## After Agent Completes

After each agent reports completion:

```bash
# In main workspace: sync to see agent's changes
jj workspace update-stale

# Review agent's work
jj diff -r <workspace-name>@

# Check for conflicts
jj status
# If conflicts shown, resolve them with jj resolve
```

**Key flow:**
1. Agent makes edits and reports completion
2. Coordinator reviews changes via `jj diff`
3. Coordinator runs `jj workspace update-stale` in main workspace
4. Conflicts surface and are resolved
5. Repeat for each agent (if multiple)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping DAG placement | Must run `jj rebase -r <ws>@ -A 'trunk()' -B mm` after creating workspace |
| Agent skipping `jj describe` | Agent must describe their changes before creating new change |
| Agent skipping `jj new` | Agent must run `jj new -A @ -B mm` after describing |
| Skipping `jj workspace update-stale` | Run in main workspace after agent completes to sync and detect conflicts |
| Creating workspaces during dispatch | Create all workspaces and place in DAG BEFORE dispatch |
| Agent touching other workspaces | Agents work ONLY in their assigned workspace path |
| Deleting workspaces before review | Keep workspaces until all work complete and reviewed |

## Red Flags - STOP

If you catch yourself thinking ANY of these, you're about to violate the workflow. **RESTART and follow the workflow exactly.**

| Red Flag | Reality |
|----------|---------|
| "I'll skip DAG placement" | NO. Must insert workspace between trunk and mm for clean integration. |
| "Agent doesn't need to describe" | NO. Agent must run `jj describe` to document the change. |
| "Agent doesn't need jj new" | NO. Agent must run `jj new -A @ -B mm` after describing. |
| "I'll create workspaces during dispatch" | Create ALL workspaces and place in DAG first. |
| "I'll skip `jj workspace update-stale`" | Run after agent completes. This syncs main workspace. |
| "I'll create a custom directory" | NO. Always use `~/src/workspaces/`. No exceptions. |
| "This is overkill for one agent" | Single-agent workflow is valid and maintains consistency. |

## Failure Recovery

**Agent times out or disappears:**
- Main session can retry that agent with fresh context
- Work in that workspace is preserved (nothing is lost)
- Other agents continue unaffected
- Retry as many times as needed

**Verification fails:**
- Agent reports what failed
- Main session can: retry agent, manually fix revisions in workspace, or revert
- Other agents' work remains clean
- No cascading failures

**Conflicts surface after `jj workspace update-stale`:**
- Expected and normal
- Main session resolves explicitly
- No emergency needed - this is why `jj workspace update-stale` exists
- Revert conflicting agent work if necessary, retry agent

**Conclusion:** All failures are contained, transparent, and recoverable.
