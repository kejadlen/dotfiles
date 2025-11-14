---
name: coordinating-subagents-with-jj-workspaces
description: Use when dispatching multiple subagents to implement independent features in parallel on a jj repository - provides explicit setup, isolation enforcement, conflict resolution, and mandatory verification to eliminate ambiguity and enable safe parallel development
---

# Coordinating Subagents with jj Workspaces

## Overview

Parallel independent feature development requires explicit coordination protocols. Without clarity, subagents break isolation (checking others' work) or lack critical information (which bookmark to use). This skill provides a rigid three-phase workflow: Setup (bookmarks + explicit instructions), Execution (enforce isolation strictly), Merge (megamerge + mandatory verification).

**Core principle:** Parallelism breaks at every ambiguity point. Eliminate ambiguity entirely. No assumptions.

## Setup Phase (Main Agent)

### 1. Create Isolated Bookmarks

Create separate jj bookmarks for each subagent, all starting from the same base:

```bash
jj bookmark create feature-auth-subagent main
jj bookmark create feature-payments-subagent main
jj bookmark create feature-analytics-subagent main
```

**Why separate bookmarks:** If all subagents share a bookmark, their commits interleave. Later merging them separately becomes impossible. Each must have its own linear history.

**Naming convention:** `feature-[descriptive-name]-subagent`. Examples:
- ✅ `feature-auth-refactor-subagent`
- ✅ `feature-stripe-integration-subagent`
- ❌ `feature-a`, `branch-1` (ambiguous in commits)

### 2. Document Everything in Writing

For EACH subagent task, write a self-contained instruction document with:

- **Bookmark name** (exact spelling, case-sensitive)
- **Files allowed to modify** (explicit whitelist, no others)
- **Files NOT to modify** (explicit blocklist)
- **Commit message format** (e.g., "auth: [verb] [noun]")
- **Tests to pass before returning** (exact commands)
- **Completion criteria** (when is work "done"?)

**Minimal example for Subagent A:**

```
FEATURE AUTH REFACTOR - Subagent A

Bookmark: feature-auth-subactor
Starting point: main
Scope: ONLY modify these files:
  - src/auth.ts
  - src/middleware/auth.js
  - tests/auth.test.ts

Do NOT modify:
  - src/payments.ts
  - src/database.ts
  - Any file outside src/

Commit format: "auth: [description]"
Examples: "auth: refactor middleware", "auth: add timeout handling"

Verification:
  npm test -- auth
  npm run lint -- src/auth.ts src/middleware/auth.js
  Both must pass before declaring complete

Do NOT:
  - Check other subagent bookmarks (they don't exist in your world)
  - Ask "what is subagent B doing?"
  - Look at other branches for context
  - Modify shared utilities without asking main agent first

Return to main agent when:
  - All tests passing (output: npm test -- auth)
  - All lint passing (output: npm run lint)
  - Commit list (output: jj log -r feature-auth-subagent)
```

**Why this level of detail:** Ambiguity is where parallelism breaks. Explicit > assumed.

### 3. Transmit Instructions to Each Subagent

Provide the exact instruction document above to EACH subagent in a separate dispatch. Do NOT ask one subagent to coordinate with another.

**Correct dispatch:**
- Task 1 (subagent A): [instruction 1 for A only]
- Task 2 (subagent B): [instruction 2 for B only]
- Task 3 (subagent C): [instruction 3 for C only]

**Incorrect dispatch:**
- "Subagents A and B, coordinate on the auth system"
- "Check if others are doing similar work"
- "You can look at branches to avoid duplication"

## Execution Phase (Subagent)

### CRITICAL: Isolation is Structural, Not Optional

Other subagents and their bookmarks do NOT EXIST to you. This isn't about "not coordinating" - they literally don't exist as entities you interact with.

### 1. Create Your Working Bookmark

Checkout your assigned bookmark:

```bash
jj checkout feature-auth-subagent
```

### 2. PROHIBITED COMMANDS

**Do NOT run ANY of these:**

```bash
jj log  # Do not see all branches
jj bookmark list  # Do not see what others are doing
jj diff -r <other-bookmark>  # Do not inspect other work
jj status -A  # Do not see repository-wide state
```

**Why:** Even "just looking" creates implicit dependencies and influences your decisions.

### 3. RED FLAGS - STOP If You Think Any Of These

If this thought crosses your mind, STOP immediately and report to main agent:

- "Let me just quickly check what subagent B is doing"
- "I should see if they're touching files I need"
- "I need to understand the repository state before starting"
- "Maybe I can reuse something from their work"
- "I should avoid conflicts by knowing what they're doing"
- "I'm just orienting myself, not really coordinating"
- "Due diligence means understanding the full picture"

**If you think any of these, respond to main agent:**
```
I'm about to start but have a question: [specific question about dependencies]
Should I proceed independently or does this indicate task decomposition was wrong?
```

Main agent decides if you have a legitimate dependency question or if you're rationalizing.

### 4. Work ONLY On Your Scope

Modify ONLY the files listed in your instruction document.

If you need to modify a file NOT on the list:
- STOP
- Report to main agent: "Feature X requires modifying [file], is this in scope?"
- Wait for answer
- Do NOT modify it without explicit approval

### 5. Commit Regularly

Small, meaningful commits following your format:

```bash
jj commit -m "auth: refactor middleware validation"
jj commit -m "auth: add timeout handling"
```

### 6. Run Your Verification BEFORE Declaring Done

Run EXACTLY the commands from your instruction document:

```bash
npm test -- auth
npm run lint -- src/auth.ts src/middleware/auth.js
```

**BOTH must pass.** If either fails, fix it. Do not declare complete if tests fail.

### 7. Report Completion

When your tests pass, report to main agent:

```
Subagent A: Feature Auth Refactor - COMPLETE

Bookmark: feature-auth-subagent
Files modified: src/auth.ts, src/middleware/auth.js, tests/auth.test.ts
Commits:
  - auth: refactor middleware validation
  - auth: add timeout handling
  - auth: update tests for new behavior

Verification:
  npm test -- auth: PASS (18/18 tests)
  npm run lint: PASS (0 issues)

Ready for integration.
```

**Do NOT add:** "I checked and subagent B isn't touching auth..." You have no knowledge of what others are doing.

## Merge Phase (Main Agent)

### Phase 1: Pre-Merge Verification

Before invoking megamerge, verify setup:

```bash
jj bookmark list | grep subagent
# Should show all three: feature-auth-subagent, feature-payments-subagent, feature-analytics-subagent

jj log -r 'feature-auth-subagent' --oneline
jj log -r 'feature-payments-subagent' --oneline
jj log -r 'feature-analytics-subagent' --oneline
# Each should show commits from respective subagent
```

**If bookmark missing:** Subagent provided wrong name or didn't commit. Ask them to verify.

**If commits absent:** Subagent committed to wrong bookmark or work is incomplete.

### Phase 2: Invoke Megamerge

Create merge change explicitly:

```bash
jj new main -m "Merge: auth refactor, payments integration, analytics tracking"
jj merge feature-auth-subagent feature-payments-subagent feature-analytics-subagent
```

**CRITICAL:** Use exact bookmark names. jj will error if names are wrong.

### Phase 3: Identify Conflicts

```bash
jj status
```

This shows files with conflicts.

If conflicts exist, you'll see conflict markers:
```
<<<<<<< Change from feature-auth-subagent
code version A
||||||| original code base
original code
=======
code version from feature-payments-subagent
>>>>>>> Change from feature-payments-subagent
```

### Phase 4: Resolve Each Conflict Manually

For EACH conflicting file:

1. **Read BOTH versions and their commits:**
   ```bash
   jj log -r feature-auth-subagent -p -- <filename>
   jj log -r feature-payments-subagent -p -- <filename>
   ```
   Understand WHY each made their change.

2. **Decide the correct resolution:**
   - Can both versions coexist? (Yes → combine them)
   - Does one take precedence? (Yes → use that version)
   - Do they need different handling? (Yes → edit both in)

3. **Edit the file to resolve:**
   Remove conflict markers. Write final code incorporating necessary parts of both versions.

4. **Verify resolution by checking for markers:**
   ```bash
   grep -r "<<<<<<" .  # Should return nothing
   grep -r "=======" .  # Should return nothing
   ```

**Do NOT:**
- Guess which version is "correct" without reading commits
- Keep both versions (that's not resolving, that's leaving conflict)
- Pick one version arbitrarily
- Skip reading the commits explaining the changes

### Phase 5: Confirm All Conflicts Resolved

```bash
jj status
# Should show NO conflicted files
# Should show modified files (your resolutions)
```

### Phase 6: Complete Merge Commit

```bash
jj describe -m "Merge: auth refactor, payments integration, analytics"
```

## Verification Phase (Main Agent) - MANDATORY

**This phase is MANDATORY. Not optional. Not conditional. Not skippable.**

Merge success (no conflicts reported) does NOT equal code validity. Semantic conflicts (logic breaks) are invisible to merge tools.

**Examples of semantic conflicts:**
- Subagent A changes function signature; Subagent B calls with old signature
- Subagent A changes initialization order; Subagent B assumes old order
- Two subagents add conflicting defaults to same config

**Merge "succeeds" for all of these.** Only verification catches them.

### You MUST Complete Every Step Below

**Pre-commitment:** Before seeing merge results, commit to running ALL steps. Not selective. All.

### Step 1: Build/Compile (MANDATORY)

```bash
npm run build
# OR equivalent for your language: cargo build, go build, python -m py_compile, etc.
```

**If this fails:** You have a semantic conflict. Merge succeeded textually, but code won't compile.

**Resolution:**
- Identify which files failed compilation
- Determine which features' changes caused it
- Edit code to fix the conflict
- Re-run build until it passes
- Re-run verification after fix

**Do NOT skip because:** "It probably compiles fine" - semantic conflicts are COMMON.

### Step 2: Run Complete Test Suite (MANDATORY)

```bash
npm test
# OR equivalent: pytest, cargo test, go test ./..., etc.
```

Run ALL tests. Not subset. All.

**If tests fail:** You have a semantic conflict in behavior. Merge succeeded, but features break each other.

**Resolution:**
- Identify which test is failing
- Find which features' changes caused the failure
- Edit code to fix the semantic conflict
- Re-run test that was failing until it passes
- Re-run full suite to ensure no regressions
- Re-run verification after fix

**Do NOT skip because:** "Tests pass independently" - integration breaks are COMMON.

### Step 3: Manual Smoke Test (MANDATORY For Features With User Workflows)

If your features have user-visible workflows, test them:

1. Start the application
2. Test workflows that involve multiple merged features
3. Verify features don't interfere (e.g., Feature A's side effect doesn't break Feature B's behavior)
4. Document: "Verified: auth login → payments checkout → analytics tracking all work together"

**If workflows fail:** You have a semantic conflict in integration. Fix, re-test, re-run step 1-2.

### Step 4: Review the Diff (MANDATORY)

```bash
jj diff main
# OR jj show (shows current change)
```

Spot-check the changes:

1. **Unexpected file deletions?** (Should be intentional)
2. **Files that shouldn't have been touched?** (Indicates over-aggressive conflict resolution)
3. **Conflict markers somehow missed?** (Unlikely but check)
4. **Massive changes to single file?** (Review for correctness)

### Step 5: Declare Completion ONLY After ALL Above Pass

Do NOT declare success until:
- Build passes
- All tests pass
- Manual smoke test passes (if applicable)
- Diff reviewed

Report to user:

```
MERGE COMPLETE

Merged bookmarks:
  ✓ feature-auth-subagent
  ✓ feature-payments-subagent
  ✓ feature-analytics-subagent

Verification:
  ✓ Build: PASS
  ✓ Tests: PASS (487/487)
  ✓ Smoke test: PASS (auth → payments → analytics workflow)
  ✓ Diff review: PASS (expected changes only)

Ready for: [deployment/review/next step]
```

**Do NOT report:** "Merge succeeded" or "No conflicts" as completion. Completion is VERIFICATION.

## Red Flags - STOP If Any Of These

### For Main Agent (Setup/Merge/Verification)

- "I'll just assume subagents know what to do" → Write explicit instructions
- "This merge seems simple, skip verification" → Verify ALL merges
- "Tests probably pass, I'll skip the full suite" → Run full suite
- "I'll compile-check instead of test" → Do both
- "Merge succeeded so we're done" → Verification hasn't started

### For Subagent (Execution)

- "Let me check what others are doing" → Ask main agent if you have a dependency
- "I'll quickly look at other bookmarks" → They don't exist
- "I should avoid conflicts by seeing their work" → Conflicts handled at merge time
- "Maybe I should wait for subagent B to finish" → No. Work independently.
- "I'll just modify one file outside scope since I'm here" → Ask main agent first

## Anti-Patterns to Avoid

❌ **Subagent checks other bookmarks** → Breaks parallelism
❌ **Main agent unsure about bookmark names** → Write them down
❌ **Skipping verification because "merge looked clean"** → Semantic conflicts are invisible
❌ **Treating merge success as terminal** → Verification is separate mandatory step
❌ **Assuming independent passing tests = integration works** → Test the integration too
❌ **Subagent waits for others to finish** → Defeats parallelism

## Example Walkthrough

### Setup (Main Agent)

```bash
# Create bookmarks
jj bookmark create feature-login-subagent main
jj bookmark create feature-oauth-subagent main

# Send explicit instructions to each subagent (separate documents)
# Instruction for Subagent A:
#   Bookmark: feature-login-subagent
#   Scope: src/login.ts, src/login.test.ts ONLY
#   Tests: npm test -- login

# Instruction for Subagent B:
#   Bookmark: feature-oauth-subagent
#   Scope: src/oauth.ts, src/oauth.test.ts ONLY
#   Tests: npm test -- oauth
```

### Execution (Subagent A)

```bash
jj checkout feature-login-subagent
# Implement login feature
jj commit -m "login: add session validation"
npm test -- login  # PASS
# Report: "Feature login complete, all tests pass"
```

### Execution (Subagent B)

```bash
jj checkout feature-oauth-subagent
# Implement OAuth feature
jj commit -m "oauth: integrate OAuth2 provider"
npm test -- oauth  # PASS
# Report: "Feature OAuth complete, all tests pass"
```

### Merge (Main Agent)

```bash
jj new main
jj merge feature-login-subagent feature-oauth-subagent
# Handle any conflicts by reading commits, understanding why, resolving
jj describe -m "Merge: login session validation + OAuth2 integration"
```

### Verification (Main Agent) - MANDATORY

```bash
npm run build  # PASS
npm test  # PASS (all 342 tests)
# Manual test: login flow → OAuth flow → combined workflow → all work
jj diff main  # Reviewed: expected changes only
# Report success
```

## Summary Checklist - MAIN AGENT

**Setup Phase:**
- [ ] Created separate bookmark for each subagent
- [ ] Wrote explicit written instructions for each
- [ ] Instructions include: bookmark name, file scope, test commands, exact commit format
- [ ] Transmitted separate instructions to each subagent (no inter-subagent communication)

**Execution Phase:**
- [ ] Subagents reported completion with bookmark name and verification output
- [ ] Each subagent's tests pass on their scope

**Merge Phase:**
- [ ] Verified all bookmarks exist
- [ ] Verified commits exist on each bookmark
- [ ] Ran megamerge with exact bookmark names
- [ ] Identified all conflicts
- [ ] Resolved each conflict by reading commits, understanding rationale, making informed decision
- [ ] Verified no conflict markers remain

**Verification Phase (MANDATORY):**
- [ ] Build passes
- [ ] Full test suite passes
- [ ] Manual smoke test passes (if applicable)
- [ ] Diff reviewed for unexpected changes
- [ ] ONLY AFTER ALL ABOVE: Reported completion to user

**DO NOT skip any verification step.**
**DO NOT declare completion without verification.**
