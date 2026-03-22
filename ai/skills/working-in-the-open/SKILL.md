---
name: working-in-the-open
description: Use when making design decisions during implementation — routes rationale to the right venue (commits, task comments, code comments, or documentation) based on how durable the context needs to be
user-invocable: false
---

# Working in the open

Capture design decisions as you work. The diff shows *what* changed; written documentation captures *why*.

## When to use

- User mentions an issue URL, number (`#123`), or identifier (`ENG-456`, `PROJ-789`)
- User says "I'm working on the X issue in [tracker]"
- Continuing work on a previously linked issue
- Making a non-obvious design choice during implementation

## Core principle

Every non-trivial design decision deserves a written record. The question isn't whether to document it — it's where.

## Where decisions belong

Route each decision to the venue that matches how long the context needs to last. These four venues form a durability scale — from the most ephemeral to the most lasting:

### Commits

The default home for design rationale. A commit message explains why *this change* was made — the problem it solves, the alternative it chose over, the constraint it works around. Most decisions need nothing more than a good commit message. See the `describing-changes` skill for how to write them.

Use commits when the decision is meaningful in the context of this specific change and a reader of the commit history would benefit from understanding the reasoning.

### Task and issue comments

Use for decisions that shaped the work but aren't tied to a single commit. Choosing between alternatives early in the process, adjusting scope after hitting a constraint, or discovering a blocker that changed the approach — these are the decisions that disappear if nobody writes them down.

Task comments capture the *journey* of a piece of work: what was considered, what was rejected, and why the final approach won. They outlive individual commits and give context that spans multiple changes.

### Code comments

Use for decisions tied to a specific implementation that will matter as long as the code exists. Constraints baked into the code, tradeoffs that explain why the code looks the way it does, or non-obvious behavior a future reader would question.

A code comment answers "why does this work this way?" at the point where the question arises. Unlike commits, code comments travel with the code through rebases, cherry-picks, and repository migrations. If removing the comment would leave a reader confused about the intent, it belongs there.

### Documentation

Use for decisions that outlive any single change, task, or block of code. Architectural patterns, conventions, API design rationale, or anything a new contributor would need to understand the system. These belong in READMEs, ADRs, design docs, or wherever the project keeps its lasting documentation.

If a decision will matter to someone who never sees the issue, the diff, or the specific code, it belongs in documentation.

## What isn't a design decision

Process narration is noise, not documentation. Don't write any of these:

- "Starting work on this issue"
- "Reviewing the schema now"
- "Planning the approach"
- "Updated the tests and CI config" (restating the diff)
- "Work is complete, opening a PR" (the PR itself signals this)

The test: would a teammate reading this six months from now learn something they couldn't get from the commits or the PR? If not, don't write it.

## Milestones worth documenting

| Milestone | Where it usually belongs | Content |
|-----------|--------------------------|---------|
| Why this change, not another | Commit message | The problem, the chosen approach, the rejected alternative |
| Choice between approaches | Task comment or commit | What was decided, what was rejected, why |
| Blocker or scope change | Task comment | What happened, how the approach adjusted |
| Non-obvious implementation | Code comment | The constraint or tradeoff that explains the code |
| Architectural pattern | Documentation | The pattern, when to use it, why it was chosen |
| Summary of a body of work | Task comment | Synthesis of decisions, scope adjustments, PR links |

## Workflow for task comments

1. **Detect** — note issue context when referenced.
2. **Filter** — after committing, ask: "Were there decisions invisible in the diff?" If yes, determine whether they belong in a task comment, code comment, or documentation.
3. **Draft** — write the update in clear prose. Focus on reasoning.
4. **Present** — show the draft to the user: "I'd like to document this on the issue. Here's the draft: [content]. Post this?"
5. **Confirm** — wait for user approval before posting.

Never post a task comment without explicit confirmation. Code comments and documentation changes go through normal code review.

## Posting task comments

Check available tools in order:

- GitHub: `gh issue comment <number> --body "..."`
- Linear/Jira: use available MCP tools
- Gitea: `tea comment` (see the `gitea` skill for syntax)
- Fallback: present the formatted comment for manual posting

## Attribution

Always attribute AI-written task comments. Begin each comment with:

> *Posted by `<program> (<model>)`*

Use your actual program and model identity. This makes clear to anyone reading the issue history that an AI wrote the comment.

## Writing quality

Design decisions are prose for humans. Write clear, concrete sentences. One paragraph that explains the reasoning well beats three that hedge. Omit needless words — but don't omit needful context.
