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
- Multiple independent features ready for parallel development
- Need to coordinate work across several subagents simultaneously
- Want unified conflict detection and resolution
- Must ensure isolation between parallel tasks
- Single-agent tasks where you want structured isolated development

**When NOT to use:**
- Tasks have dependencies (use sequential development)
- Features require constant coordination (use pair programming)

## The Workflow Checklist

**CRITICAL: Create TodoWrite todos for EACH step below. This workflow has sequential gates.**

### Phase 1: Define and Setup (Main Session)

- [ ] Define task specifications for each agent (goal, requirements, success criteria, verification steps)
- [ ] Create isolated workspaces: `jj workspace add <name> <path>` for each task (one per agent)
- [ ] Verify EVERY workspace is isolated and ready (DO NOT proceed to Phase 2 until ALL workspaces verify successfully)
- [ ] **BLOCKER:** Phase 1 MUST be 100% complete before ANY agent dispatch. Dispatching even one agent early breaks isolation guarantees.

### Phase 2: Dispatch Agents (Main Session)

- [ ] For each task, dispatch subagent with: task spec + workspace path + verification steps
- [ ] All dispatches happen in parallel (use Task tool with multiple invocations)
- [ ] Main session monitors for agent completion

### Phase 3: Execution and Incremental Validation (Agents + Main Session in Parallel)

**Agents (in parallel):**
- [ ] Agent works independently in their assigned isolated workspace
- [ ] Agent runs verification steps (tests, checks) locally
- [ ] Agent shows `jj diff` output to main session
- [ ] Agent waits for main session code review and approval
- [ ] Only after approval: Agent uses `jj describe -m "message"` to add message to current change
- [ ] Agent uses `jj new --insert-after=@` to start a new change
- [ ] Agent reports completion status

**Main session (as each agent reports ready):**
- [ ] As each agent reports ready for review, immediately:
  - [ ] Review their `jj diff` changes for code quality
  - [ ] Verify their local verification results passed
  - [ ] Approve or request changes
  - [ ] Once approved: tell agent to describe and create new change
  - [ ] After agent confirms workspace is updated: run `jj workspace update-stale`
  - [ ] Check for conflicts and resolve if needed
  - [ ] Workspace automatically stays in megamerge history
  - [ ] Proceed to next agent
- [ ] Repeat until ALL agents complete and all conflicts resolved

### Phase 4: Cleanup (Main Session)

- [ ] Delete workspaces: `jj workspace forget <name>`
- [ ] Remove isolated workspace directories
- [ ] All agent work remains in the jj repository history

## Setup: Creating or Reusing Workspaces

**Before dispatching ANY agents, execute this setup:**

**MANDATORY location:** `~/src/workspaces/` - This is the fixed, standard location across all projects.

**Workspace naming:** `{jira-id-if-present}-{feature-name}` - Include JIRA ID as prefix ONLY if work is tracked in JIRA. Use LOWERCASE only.

**DO NOT deviate from this structure.** Do not create custom directories like `-workspaces`, `parallel-work`, `subagent-work`, etc.

```bash
# EXACT pattern for workspaces (all lowercase)
jj workspace add --revision "trunk()" ~/src/workspaces/proj-123-auth
jj workspace add --revision "trunk()" ~/src/workspaces/api-feature
jj workspace add --revision "trunk()" ~/src/workspaces/db-migration
```

**NO custom paths. NO alternative directories. ALWAYS use `~/src/workspaces/`**

**Key enforcement:**
- Workspaces are created BEFORE agents start (not during)
- Each workspace is completely isolated (cannot see other agent work)
- Each workspace has its own independent jj state
- Default location is `~/src/workspaces` for consistency across projects
- JIRA IDs in workspace names provide automatic traceability

**Reusing existing workspaces:**
- Verify workspace exists: `jj workspace list`
- Check its current state: `jj -R /path/to/workspace status`
- Workspaces may be reused for multiple agent cycles - they're just isolated directories

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
1. Work ONLY in their assigned workspace (cd to workspace path first)
2. Run verification steps provided in task spec
3. Report work status to main session with: changes made, test results, diff of changes
4. **WAIT for main session approval** before describing changes
5. Only after approval: Use `jj describe -m "message"` to add description to current change
6. Then use `jj new --insert-after=@` to start a new change for the megamerge
7. Report completion: "Described and new change created" or specific blockers
8. Make NO changes outside their workspace
9. Make NO attempt to check other agent workspaces
10. Do NOT attempt to merge or integrate their work

**Agent workflow:**
- Make changes and verify locally
- Show `jj diff` output to main session
- Wait for code review approval
- After approval: run `jj describe -m "message"` to describe current change
- Then: run `jj new --insert-after=@` to create new change for next work
- Report final status

**If verification fails:**
- Agent reports what failed and why
- Agent attempts one retry OR hands off to main session
- Agent does NOT commit failed work

**Main session handles:**
- Review agent changes before describe
- Approve or request changes
- Conflict resolution after `jj workspace update-stale`
- Decision about failed verification (retry, fix, or revert)

## After Each Agent Describes Changes

After each agent reports they've described changes and created new change:

```bash
# Update workspace to see other agents' changes
jj workspace update-stale

# Check for conflicts - if conflicts appear, resolve them
jj status
# If conflicts shown, resolve them with jj resolve
```

**Key flow:**
1. Agent uses `jj describe -m "message"` to add description to their work
2. Agent uses `jj new --insert-after=@` to create new change in megamerge
3. Main session runs `jj workspace update-stale` to pull in all changes
4. Workspace automatically stays in megamerge history
5. Conflicts automatically surface and are resolved locally
6. Repeat for each agent

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Agents working sequentially | Dispatch with Task tool in PARALLEL, not sequentially |
| Manual coordination between agents | Agents work in isolated workspaces, zero communication |
| Creating workspaces during dispatch | Create all workspaces in Phase 1 BEFORE any agent starts |
| Dispatching agents before ALL workspaces ready | Phase 1 MUST complete 100% before ANY Phase 2 dispatch |
| Agent describing without approval | Agents MUST wait for main session code review before describing |
| Agent not using `jj describe` | Must describe changes with `jj describe -m "message"` |
| Agent not creating new change | Must use `jj new --insert-after=@` to start new change for megamerge |
| Skipping `jj workspace update-stale` | Run after each agent describes to detect conflicts |
| Agent touching other workspaces | Agents work ONLY in their assigned workspace |
| Deleting workspaces before review | Keep workspaces until all agents complete and conflicts resolved |
| Not resolving conflicts as they appear | Resolve conflicts immediately after `jj workspace update-stale` |

## Red Flags - STOP

If you catch yourself thinking ANY of these, you're about to violate the workflow. **All of these mean: RESTART and follow the workflow exactly.**

| Red Flag | Reality |
|----------|---------|
| "I'll dispatch agents one at a time" | Defeats parallelism. Dispatch ALL at once with Task tool parallel calls. |
| "Agents should check each other's work" | Complete isolation guaranteed. Agents never see other workspaces. Period. |
| "I'll create workspaces during dispatch" | Create ALL workspaces in Phase 1 first. Dispatching early breaks isolation. |
| "Agent can describe without approval" | Agents MUST wait for main session review. Approval gate is mandatory. |
| "Agent doesn't need to describe changes" | NO. Must use `jj describe -m "message"` to capture work description. |
| "Agent doesn't need new change" | NO. Must use `jj new --insert-after=@` to keep workspace in megamerge. |
| "Verification can happen later" | Agents must verify and report BEFORE handing off to main session. |
| "I'll skip `jj workspace update-stale`" | Run after each agent describes. This is how conflicts surface and get resolved. |
| "I'll resolve conflicts after all agents done" | Resolve conflicts immediately as each agent completes. Early detection = easier. |
| "Just one workspace can be created during dispatch" | Phase 1 MUST complete 100% first. Partial setup breaks isolation guarantees. |
| "I'll create a custom `-workspaces` directory" | NO. Always use `~/src/workspaces/`. No exceptions, no alternatives. |
| "This is overkill for just 2 agents" | Isolation discipline scales. Cut corners now, deal with conflicts later. |

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
