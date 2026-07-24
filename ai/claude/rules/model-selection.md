# Model Selection

Default to Opus for interactive sessions. Drop down when the task is
clearly mechanical.

## Opus

The default. Interactive coding, reasoning, architecture decisions,
multi-file refactors, debugging, writing, code review — anything
involving judgment or conversation.

## Sonnet

Subagents, background tasks, well-scoped autonomous work where the
instructions are clear and the task is bounded.

## Haiku

Commit messages, simple lookups, formatting, mechanical edits, generating
boilerplate. Anywhere speed matters more than depth.

## When to question the default

Opus is wrong when:
- The task is bounded and well-specified — Sonnet finishes faster at
  near-identical quality. Long Opus sessions on mechanical work waste
  latency and cost.
- You're iterating in a tight loop (manual edits, repeated small
  prompts). Sonnet's speed compounds.
- You're using Fast mode out of habit but the work is exploratory —
  the speed bias is hiding under-thought design.

Signals to drop a level mid-session:
- You're correcting Claude on simple facts more than once.
- The remaining work is mechanical follow-through on a decided plan.
- You're paying for a 1M context window on a 20k-token task.

## When spawning subagents

The tiers above are defaults, not a lookup table to apply mechanically.
Use judgment on the actual subtask rather than defaulting every subagent
to Sonnet: a complex multi-file refactor delegated to a subagent may
still warrant Opus, while a one-line lookup fits Haiku even run inline.

Reserve the main loop's reasoning for judgment-heavy work — design,
review, synthesis — once an approach is decided, delegate the
implementation and let the choice of subagent tier follow from what the
subtask actually needs.
