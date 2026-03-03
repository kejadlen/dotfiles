---
name: working-in-the-open
description: Use when doing work on a tracked issue (GitHub, Jira, Linear, etc) — documents decisions, blockers, and summaries as comments on the issue for historical record
---

# Working in the Open

Document the reasoning behind code changes as you work. The diff shows *what* changed; issue comments capture *why*.

## When to Use

- User mentions an issue URL, number (`#123`), or identifier (`ENG-456`, `PROJ-789`)
- User says "I'm working on the X issue in [tracker]"
- Continuing work on a previously-linked issue

## Default: Don't Comment

**Most work does not need a comment.** The commit message is the record. Only comment when you have context the commit cannot capture — a decision between alternatives, a blocker that changed scope, or a summary the user explicitly asked for.

Before even considering a comment, ask: "Does this say something the commit doesn't?" If no, skip it entirely — don't draft it, don't propose it, don't ask the user about it.

### Specifically, Do NOT Comment When

- **Work is complete and a PR is being opened.** The PR links to the issue and serves as the summary.
- **The comment would restate the commit message.** Even partially. "Switched X to Y, updated CI" after a commit that says exactly that is pure noise — regardless of whether it's phrased differently.
- **You're announcing you're starting work.** The state change (→ in_progress) already signals that.
- **The work was straightforward.** If there were no surprises, no alternatives considered, no scope changes — there's nothing to document beyond the commit.

## The Three Milestones

| Milestone | Trigger | Content |
|-----------|---------|---------|
| **Decision** | Non-obvious choice between alternatives | What was decided, what alternatives existed, why this approach won |
| **Blocker/Scope Change** | Unexpected impediment or deviation from plan | What happened, how the approach adjusted |
| **Summary** | User requests, or natural breakpoint in work | Synthesis of work done, key decisions, scope adjustments, PR links |

## Workflow

1. **Detect** — Note issue context when referenced
2. **Filter** — After committing, ask: "Does this need a comment, or does the commit say it all?" Default answer is no. Only proceed if there's genuinely new context (a decision rationale, a blocker, a scope change).
3. **Draft** — Write update in appropriate format
4. **Present** — Show draft to user: "I'd like to document this on the issue. Here's the draft: [content]. Post this?"
5. **Confirm** — Wait for user approval before posting

Never post without explicit confirmation. But more importantly, don't even propose comments that restate commits.

## Posting

Check available tools in order:
- GitHub: `gh issue comment <number> --body "..."`
- Linear/Jira: Use available MCP tools
- Fallback: Present formatted comment for manual posting

## Attribution

Always attribute comments to yourself. Begin each comment with:

> *Posted by `<program> (<model>)`*

Use your actual program and model identity as shown in the system prompt. This makes it clear to anyone reading the issue history which AI and program wrote the comment.

## Format Guidance

Write clear prose, not templates. Focus on:
- **Decisions**: The alternatives considered and reasoning — invisible in the diff
- **Blockers**: What changed and why — explains gaps between ask and delivery
- **Summaries**: Coherent narrative — easier than piecing together commits

Keep updates concise. One clear paragraph beats three hedging ones.
