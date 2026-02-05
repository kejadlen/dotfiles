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

## The Three Milestones

| Milestone | Trigger | Content |
|-----------|---------|---------|
| **Decision** | Non-obvious choice between alternatives | What was decided, what alternatives existed, why this approach won |
| **Blocker/Scope Change** | Unexpected impediment or deviation from plan | What happened, how the approach adjusted |
| **Summary** | User requests, or natural breakpoint in work | Synthesis of work done, key decisions, scope adjustments, PR links |

## Workflow

1. **Detect** — Note issue context when referenced
2. **Recognize** — Identify milestone moments during work
3. **Draft** — Write update in appropriate format
4. **Present** — Show draft to user: "I'd like to document this on the issue. Here's the draft: [content]. Post this?"
5. **Confirm** — Wait for user approval before posting

Never post without explicit confirmation.

## Posting

Check available tools in order:
- GitHub: `gh issue comment <number> --body "..."`
- Linear/Jira: Use available MCP tools
- Fallback: Present formatted comment for manual posting

## Format Guidance

Write clear prose, not templates. Focus on:
- **Decisions**: The alternatives considered and reasoning — invisible in the diff
- **Blockers**: What changed and why — explains gaps between ask and delivery
- **Summaries**: Coherent narrative — easier than piecing together commits

Keep updates concise. One clear paragraph beats three hedging ones.
