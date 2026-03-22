---
name: design-notes
description: Use when starting non-trivial implementation work, when design decisions risk being buried in generated code, or when scoping a feature before writing code
---

# Design notes

Supplementary notes on designing software with AI, accumulated from experience and external sources.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## The implementation trap

AI collapses design and implementation into a single step. Describe a feature, receive hundreds of lines — with every architectural decision made silently. The first time you see the AI's design thinking is when you're reading code, which is the most expensive place to discover a disagreement.

Reviewing AI-generated code feels more exhausting than reviewing a colleague's work because you're evaluating scope, architecture, integration, contracts, and code quality simultaneously. That's too many dimensions for a single pass.

**Core constraint:** No code until the design is agreed. Everything else follows from there.

## Progressive design alignment

Walk through progressive levels of design before writing code. Each level surfaces a category of decisions that would otherwise be buried in the implementation.

| Level | Focus | Question it answers |
|-------|-------|-------------------|
| Capabilities | What the system needs to do | Are we building the same thing? |
| Components | Building blocks — services, modules, abstractions | Do the boundaries make sense? |
| Interactions | How components communicate — data flow, APIs, events | Does the integration fit? |
| Contracts | Interfaces, function signatures, types, schemas | Do the shapes match? |
| Implementation | Now write the code | — |

Present each level separately. Wait for approval before moving to the next. This is cognitive load management — one category of decision at a time, not all of them at once.

## Calibrating depth to complexity

Not every task needs all five levels. Scale to the work:

| Task complexity | Start at | Example |
|----------------|----------|---------|
| Simple utility | Contracts | Date formatter, string helper |
| Single component | Components | Validation service, API endpoint |
| Multi-component feature | Capabilities | Notification system, payment integration |
| New system integration | Capabilities + deep Interactions | Third-party API, event-driven pipeline |

## Why this pays off

- Catching a scope mismatch in a two-minute design conversation costs less than discovering it woven through 400 lines of generated code (Boehm's Cost of Change Curve still applies).
- Agreed-upon contracts create preconditions for TDD — approve contracts, generate tests, then implement against them.
- AI tends to add unrequested features (rate limiting, analytics hooks, webhook systems). Explicit scope at the Capabilities level prevents this technical debt injection.
- Design alignment compounds with knowledge priming — when the AI already understands the project's architecture and conventions, each design level is anchored to the codebase.

## Sources

- [Design-First Collaboration](https://martinfowler.com/articles/reduce-friction-ai/design-first-collaboration.html) (Rahul Garg, martinfowler.com, 2026)
