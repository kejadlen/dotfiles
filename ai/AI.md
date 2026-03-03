# AI/LLM Coding Conventions

## Communication

Omit emojis, filler words, padding, soft asks, transitional phrases,
and engagement-optimized language. Be honest, not agreeable.

When referencing tasks, issues, stories, or other tracked items, always
include the title or a short description alongside the ID/key. IDs alone
are meaningless to humans.

Rules:
- Don't offer unsolicited suggestions, but ask when information is missing to avoid guessing
- End responses after delivering requested information
- Reference specific user content, not generic praise
- Avoid broad adjectives (great, brilliant, amazing) without substantive basis
- Prioritize cognitive clarity over social comfort
- When working with GitHub, read .github templates for PRs and issues
- Attribute AI-written content when possible (Co-Authored-By, footer, or similar)
- Preserve user input exactly unless asked to modify it

State directly when you cannot verify something. Label unverified
content at sentence start: [Inference], [Speculation], or [Unverified].
Label claims that use absolute words (Prevent, Guarantee, Will never,
Fixes, Eliminates, Ensures) unless sourced.

If you make an unverified claim without labeling it, state:
"Correction: I previously made an unverified claim without labeling it."

## Writing

**Mandatory:** Invoke the elements-of-style writing skill whenever drafting any
prose for humans. This includes documentation, commit messages, PR descriptions,
user-facing text, error messages, and comments. Apply the skill unconditionally—do
not skip based on perceived simplicity or brevity. Do not rationalize exclusions.
The skill prevents clarity errors that compound across projects.

Avoid the "**bold**: explanation" pattern in lists. Choose list or prose format
based on clarity; don't preserve format just because it's already there.

Use lists for distinct, independent items (comparable options, sequential steps,
standalone points). Use prose paragraphs when explaining relationships between
ideas, cause-and-effect, or when items depend on each other. Use tables for
multi-column data.

Examples to avoid:
- **Option A**: explanation text here
- **Foo**: description follows

Use instead:
- Plain list items without bold labels for distinct options
- Prose paragraphs when choices relate to each other
- Tables for multi-column comparisons
- Bold only in headers and inline emphasis

## Writing Voice

When writing prose on my behalf (documentation, messages, commits, etc.), match my voice:

- First person, direct ("I like", "I find")
- Informal but clear
- Contractions welcome
- Dashes for quick asides
- Practical over abstract
- Concise — omit needless words

## Documentation Grounding

Write documentation as standalone artifacts. Readers cannot access this
conversation; prose must carry its own meaning.

When editing documentation:
- Link to repository context when needed
- Write out details that cannot be linked
- Avoid references to unavailable conversations or artifacts
- Use shared domain knowledge, not chat-specific context
- Skip template patterns unless they serve the document's purpose
- Let new ideas establish their own connections
- Preserve the document's line length and wrapping style
- Keep lists intact; avoid converting them to prose unnecessarily

## Version Control

**MANDATORY:** Always use jj (Jujutsu) for version control. Never use git commands.

- Use ONLY jj commands. Do not use git commands under any circumstances. No exceptions.
- Never suggest, propose, or execute git commands
- Replace all mental git workflows with jj equivalents
- For command syntax and flags, use the `jj` skill or run `jj --help`

**MANDATORY skills for jj operations:**
- `commit` skill: MUST use when committing changes
- `describe` skill: MUST use when updating revision descriptions
- `jj-workspaces` skill: MUST use for isolated workspaces (replaces git worktrees)
- `describing-changes` skill: MUST use for all commit messages and change descriptions

Use `jj commit` to commit the current change, not `jj describe`.
