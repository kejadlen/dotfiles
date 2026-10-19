# Model selection for subagents

When you spawn a subagent, pick its model from what the subtask needs:

- Opus for judgment: design, debugging, multi-file refactors, review.
- Sonnet for bounded, well-specified work with clear instructions.
- Haiku for mechanical work: lookups, formatting, boilerplate.

These are defaults, not a lookup table. A complex refactor handed to a
subagent may still warrant Opus; a one-line lookup fits Haiku.
