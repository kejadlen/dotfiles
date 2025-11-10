---
name: Creating Skills
description: |
  Write failing test first, then skill, then verify - no exceptions for time
  pressure or simple topics
version: 2.0.0
---

# Creating Skills

## Overview

**Test-Driven Development for documentation.** Write test case with Task agent
(watch it fail), write skill (minimal), run test again (watch it pass).

**Skills are written to `ai/claude/skills/` in this repository.**

**Core principle:** If you didn't watch an agent fail without the skill, you
don't know if the skill works.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools.
Skills help future Claude instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with Task agent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill (baseline) |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

The entire skill creation process follows RED-GREEN-REFACTOR.

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in CLAUDE.md)

## Skill Types

### Technique
Concrete method with steps to follow (debugging workflows, testing patterns)

### Pattern
Way of thinking about problems (code organization, refactoring approaches)

### Reference
API docs, syntax guides, tool documentation (framework references)

## Directory Structure

**All skills are in `ai/claude/skills/`:**

```
ai/claude/skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

**Flat namespace** - all skills in one searchable location

**Separate files for:**
1. **Heavy reference** (100+ lines) - API docs, comprehensive syntax
2. **Reusable tools** - Scripts, utilities, templates

**Keep inline:**
- Principles and concepts
- Code patterns (< 50 lines)
- Everything else

## SKILL.md Structure

```markdown
---
name: Human-Readable Name
description: One-line summary of what this does
version: 1.0.0
dependencies: (optional) Required tools/libraries
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns
Link to separate file for heavy reference or reusable tools

## Common Mistakes
What goes wrong + fixes

## Real-World Impact (optional)
Concrete results
```

## Claude Search Optimization (CSO)

**Critical for discovery:** Future Claude needs to FIND your skill

### 1. Keyword Coverage

Use words Claude would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### 2. Descriptive Naming

**Use active voice, verb-first:**
- ✅ `creating-skills` not `skill-creation`
- ✅ `testing-skills-with-agents` not `agent-skill-testing`

### 3. Token Efficiency

**Target word counts:**
- Frequently-loaded skills: <200 words total
- Other skills: <500 words (still be concise)

**Techniques:**

**Reference tool help:**
```bash
# ❌ BAD: Document all flags in SKILL.md
git supports --patch, --interactive, --verbose options

# ✅ GOOD: Reference --help
git supports multiple modes. Run --help for details.
```

**Use cross-references:**
```markdown
# ❌ BAD: Repeat workflow details
When searching, use Task agent with template...
[20 lines of repeated instructions]

# ✅ GOOD: Reference other skill
Always use Task agents (context savings). See creating-skills for workflow.
```

**Name by what you DO or core insight:**
- ✅ `systematic-debugging` > `debugging-techniques`
- ✅ `using-skills` not `skill-usage`
- ✅ `defensive-coding` > `error-handling-patterns`

**Gerunds (-ing) work well for processes:**
- `creating-skills`, `testing-skills`, `debugging-with-logs`
- Active, describes the action you're taking

### 4. Content Repetition

Mention key concepts multiple times:
- In description
- In overview
- In section headers

Grep hits from multiple places = easier discovery

## Code Examples

**One excellent example beats many mediocre ones**

Choose most relevant language:
- Testing techniques → TypeScript/JavaScript
- System debugging → Shell/Python
- Data processing → Python

**Good example:**
- Complete and runnable
- Well-commented explaining WHY
- From real scenario
- Shows pattern clearly
- Ready to adapt (not generic template)

**Don't:**
- Implement in 5+ languages
- Create fill-in-the-blank templates
- Write contrived examples

You're good at porting - one great example is enough.

## File Organization

### Self-Contained Skill
```
defense-in-depth/
  SKILL.md    # Everything inline
```
When: All content fits, no heavy reference needed

### Skill with Reusable Tool
```
test-patterns/
  SKILL.md    # Overview + patterns
  example.ts  # Working helpers to adapt
```
When: Tool is reusable code, not just narrative

### Skill with Heavy Reference
```
api-reference/
  SKILL.md       # Overview + workflows
  api-docs.md    # 600 lines API reference
  examples/      # Code samples
```
When: Reference material too large for inline

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

**Write skill before testing? Delete it. Start over.**

This applies to NEW skills AND EDITS to existing skills.

**No exceptions for:**
- Time pressure
- Simple topics
- Comprehensive documentation
- Fatigue
- Confidence in quality
- "Simple additions"
- "Just adding a section"
- "Documentation updates"

Don't keep untested changes as "reference". Don't "adapt" while running tests. Delete means delete.

## Testing All Skill Types

Different skill types need different test approaches:

### Discipline-Enforcing Skills (rules/requirements)

**Examples:** TDD, verification-before-completion, designing-before-coding

**Test with:**
- Academic questions: Do they understand the rules?
- Pressure scenarios: Do they comply under stress?
- Multiple pressures combined: time + sunk cost + exhaustion
- Identify rationalizations and add explicit counters

**Success criteria:** Agent follows rule under maximum pressure

### Technique Skills (how-to guides)

**Examples:** systematic debugging, test patterns, defensive programming

**Test with:**
- Application scenarios: Can they apply the technique correctly?
- Variation scenarios: Do they handle edge cases?
- Missing information tests: Do instructions have gaps?

**Success criteria:** Agent successfully applies technique to new scenario

### Pattern Skills (mental models)

**Examples:** reducing-complexity, information-hiding concepts

**Test with:**
- Recognition scenarios: Do they recognize when pattern applies?
- Application scenarios: Can they use the mental model?
- Counter-examples: Do they know when NOT to apply?

**Success criteria:** Agent correctly identifies when/how to apply pattern

### Reference Skills (documentation/APIs)

**Examples:** API documentation, command references, library guides

**Test with:**
- Retrieval scenarios: Can they find the right information?
- Application scenarios: Can they use what they found correctly?
- Gap testing: Are common use cases covered?

**Success criteria:** Agent finds and correctly applies reference information

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Time pressure - I'll test later" | Later = never. Test first takes 5 minutes. |
| "Too simple to need testing" | Simple skills fail too. Test it. |
| "I already know what agents will do" | You don't. Test it. |
| "Comprehensive docs = quality" | Comprehensive ≠ useful. Test with agent. |
| "Testing is overkill for docs" | Untested docs waste more time debugging. |
| "I'll follow the skill structure" | Structure is GREEN phase. Must do RED first. |
| "The skill shows documentation format" | That's what to write AFTER testing. Test first. |
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |

**All of these mean: Write test first. No exceptions.**

## Red Flags - STOP and Start Over

- Writing skill before testing
- "I'll just quickly document this"
- "Testing seems excessive"
- "This is different because [time/simplicity/authority]"
- Already wrote skill, considering whether to test

**All of these mean: Delete untested content. Start with RED phase.**

## Bulletproofing Skills Against Rationalization

Skills that enforce discipline (like TDD) need to resist rationalization.
Agents are smart and will find loopholes when under pressure.

### Close Every Loophole Explicitly

Don't just state the rule - forbid specific workarounds:

<Bad>
```markdown
Write code before test? Delete it.
```
</Bad>

<Good>
```markdown
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```
</Good>

### Address "Spirit vs Letter" Arguments

Add foundational principle early:

```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

This cuts off entire class of "I'm following the spirit" rationalizations.

### Build Rationalization Table

Capture rationalizations from baseline testing. Every excuse agents make goes in the table:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
```

### Create Red Flags List

Make it easy for agents to self-check when rationalizing:

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

## Quick Reference: RED-GREEN-REFACTOR

| Phase | Action | Evidence |
|-------|--------|----------|
| **RED** | Run Task agent WITHOUT skill | Document what agent does wrong |
| **GREEN** | Write minimal skill addressing failures | Task agent now succeeds |
| **REFACTOR** | Find new loopholes | Plug holes, re-test |

## RED-GREEN-REFACTOR for Skills

**STOP: Before doing ANYTHING else, start with RED phase.**

You do NOT have permission to write skill documentation until you complete RED phase.

### RED: Write Failing Test (REQUIRED FIRST STEP)

Create pressure scenario. Use Task tool to launch agent WITHOUT the skill.

```
Task agent prompt:
"IMPORTANT: You do NOT have access to any skills about [topic].
Respond naturally based on your default behavior.

[Pressure scenario]. Create documentation for [topic] at [path]."
```

Observe and document verbatim:
- What did agent do?
- What rationalizations did it use?
- What should it have done instead?

**Pressure types** (combine 2-3):
- Time: "Need this for standup in 15 min"
- Sunk cost: "Already spent 2 hours writing this"
- Authority: "Tech lead says ship it"
- Exhaustion: "It's 11 PM"
- Confidence: "This is obvious and straightforward"

**If you skipped this step and wrote documentation first: Delete it. Start over with RED phase.**

### GREEN: Write Minimal Skill

Address specific failures observed in RED. Don't add hypothetical content.

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter.

Build rationalization table from all test iterations.

Re-test until bulletproof.

## Testing with Task Agents

Use the Task tool to launch specialized agents for testing:

```markdown
# Test scenario
Task agent prompt:
"You're under time pressure to ship a feature. Write a function that validates email addresses. The PM is waiting for a demo in 10 minutes."

# Baseline (without skill)
- Agent writes implementation first
- Adds tests after
- Rationalizes: "I can test faster manually"

# With skill present
- Agent writes test first
- Implementation follows
- Complies with TDD discipline
```

**Pressure types to combine:**
- Time pressure: "PM waiting for demo"
- Sunk cost: "You already wrote 100 lines"
- Authority: "Senior dev said to ship it"
- Exhaustion: "You've been debugging for 3 hours"

## Anti-Patterns

### ❌ Narrative Example
"In session 2025-10-03, we found empty projectDir caused..."
**Why bad:** Too specific, not reusable

### ❌ Multi-Language Dilution
example-js.js, example-py.py, example-go.go
**Why bad:** Mediocre quality, maintenance burden

### ❌ Generic Labels
helper1, helper2, step3, pattern4
**Why bad:** Labels should have semantic meaning

## STOP: Before Moving to Next Skill

**After writing ANY skill, you MUST STOP and complete the deployment process.**

**Do NOT:**
- Create multiple skills in batch without testing each
- Move to next skill before current one is verified
- Skip testing because "batching is more efficient"

**The deployment checklist below is MANDATORY for EACH skill.**

Deploying untested skills = deploying untested code. It's a violation of quality standards.

## Skill Creation Checklist (TDD Adapted)

**RED Phase - Write Failing Test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill - document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase - Write Minimal Skill:**
- [ ] Name describes what you DO or core insight
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Clear overview with core principle
- [ ] Address specific baseline failures identified in RED
- [ ] Code inline OR link to separate file
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill - verify agents now comply

**REFACTOR Phase - Close Loopholes:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**
- [ ] Quick reference table
- [ ] Common mistakes section
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**Deployment:**
- [ ] Test skill with Task agents under pressure
- [ ] Commit to version control

## Discovery Workflow

How future Claude finds your skill:

1. **Encounters problem** ("tests are flaky")
2. **Searches skills** using grep in `ai/claude/skills/`
4. **Scans overview** (is this relevant?)
5. **Reads patterns** (quick reference table)
6. **Loads example** (only when implementing)

**Optimize for this flow** - put searchable terms early and often.

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
Same benefits: Better quality, fewer surprises, bulletproof results.

If you follow TDD for code, follow it for skills. It's the same discipline applied to documentation.

Test-first for documentation. Same as code. No exceptions for time, simplicity, or confidence.
