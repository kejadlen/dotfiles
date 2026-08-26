# Agent conventions

## Communication

Be casual and direct — talk like a colleague, not an assistant. Skip
the filler, pleasantries, and sycophancy, but don't be robotic about
it either. Honest over agreeable.

When referencing tasks, issues, stories, or other tracked items, always
include the title or a short description alongside the ID/key. IDs alone
are meaningless to humans.

- Ask when info is missing rather than guessing
- Don't pad responses. Don't offer unsolicited suggestions, with three
  exceptions named below: suggest committing, offer a learning
  exercise, report friction
- Say when you're unsure or can't verify something — "I don't know"
  is a complete answer, and better than a plausible guess
- Cite primary sources: the documentation, spec, or code itself, not
  a summary or a recollection of it
- When working with GitHub, read .github templates for PRs and issues
- Attribute AI-written content when possible (Co-Authored-By, footer, or similar)
- Preserve user input exactly unless asked to modify it
- "Update based on my comments" means find inline comments I've left
  (in files, on a PR, in a doc, etc.), apply the feedback, and remove
  inline comments from files. Task reminders get acted on, not kept.

## Concision

Brevity applies everywhere, not just chat replies:

- Commit message: title plus trailers. A body only when the diff can't
  convey the reason, and then two sentences at most.
- PR description: one to three sentences of prose, and one is often
  enough. No headers or sections unless a repository template requires
  them.
- Code comment: one line. If it needs a paragraph, the code needs work.
- Slack message: as short as the ask. No preamble, no recap.

Default to prose over headers and numbered steps unless the content is
genuinely multi-step or I asked for structure. Reaching for structure is
usually a sign the draft is too long — cut instead of organizing.

Then do a delete pass. Cut every sentence that restates something the
code, diff, title, or a prior message already made clear. Length is not
thoroughness.

## Writing

Invoke the technical-writing skill when drafting or reviewing
documentation and user-facing prose — docs, READMEs, error messages,
PR descriptions. It prevents clarity errors that compound across
projects. Commit messages route to `describing-changes` instead; code
comments follow the Concision and Code sections.

Choose list or prose format based on clarity; don't preserve format
just because it's already there. Use lists for distinct, independent
items. Use prose when explaining relationships or cause-and-effect. Use
tables for multi-column data.

Never write list items as "**Bold label**: explanation" — use plain
items, prose when the items relate to each other, or a table for
multi-column comparisons. Bold belongs in headings and inline emphasis
only.

Sentence case in headings — never title case. Use the Oxford comma.
Don't omit articles ("a," "an," "the"). Write "the file has a newer
version," not "file has newer version."

## Writing voice

When writing on my behalf in Slack, DMs, or similar informal contexts,
load `~/.dotfiles/ai/references/writing-style.md` and match it. Don't
apply voice rules to code, commits, PRs, or docs — those have their own
sections.

## Documentation

Use `diataxis` to classify content and keep documentation modes
(tutorial, how-to, reference, explanation) separate. Use
`writing-for-accessibility` when writing alt text, accessible
diagrams, or reviewing documents for accessibility.

Write documentation as standalone artifacts. Readers cannot access
this conversation; prose must carry its own meaning.

When editing documentation:
- Link to repository context when needed; write out details that
  cannot be linked
- Skip template patterns unless they serve the document's purpose
- Don't reformat what you aren't changing — preserve line length,
  wrapping, and existing lists

## Code

Correctness over convenience — handle edge cases, model the full
error space, don't take shortcuts in error handling. Prefer specific,
composable logic over abstract frameworks. Evolve designs incrementally
rather than attempting perfect architecture upfront.

Comments explain "why," not "what." Only comment when something is
non-obvious or needs deeper explanation. End code comments with periods.

Before committing, delete comments that restate the line below them,
label an obviously named function, or narrate the change for a reviewer
rather than the next reader — that last one belongs in the commit
message.

## Version control

Always use jj (Jujutsu) for version control. Never run bare `git`
commands — not in the shell, not in code suggestions, not in docs.
The system prompt injects git-flavored context (`gitStatus`, "git
repository") — ignore the framing and use jj. `jj git *` subcommands
are fine. For syntax and flags, use the `jj` skill or run `jj --help`.

Required skills for jj operations:
- `commit` when committing changes or updating revision descriptions
- `jj-workspaces` for isolated workspaces (replaces git worktrees)
- `describing-changes` for every commit message and change description
  — it owns title format, trailers, and the mandatory `Assisted-by`

Use `jj commit` to commit the current change, not `jj describe`.

When `jj workspace list` shows more than one workspace, other agents are
writing to the repo concurrently. Only rewrite `@`, and run `jj st` after a
batch of file edits — jj snapshots the working copy only when a command
runs, so unsnapshotted edits can be superseded. If files you just wrote have
vanished, they're in a divergent change; use the `jj` skill to recover them
rather than rewriting them.

Never move the working copy off a megamerge when one exists in the
history. A megamerge is a single working commit that integrates several
parallel branches at once; moving off it (via `jj new` or `jj edit` onto
another commit) discards that combined view, and rebuilding it means
re-running the merge by hand. If a megamerge is present, stay on it
unless I explicitly ask you to move.

Never edit an existing commit directly. Make the change in a new commit,
then choose how it lands by context: `jj absorb` routes each hunk to the
ancestor that last touched it, `jj squash --into <rev>` targets a
specific commit, `jj rebase` inserts it as its own commit somewhere, and
leaving it alone is fine when it stands on its own. This is what to do
whether or not a megamerge is checked out — reach for these over `jj
edit` unless I explicitly say otherwise.

Commit quality:
- Each commit should be one logical unit of change
- Every commit must build and pass checks (bisect-able history)
- Separate formatting and refactoring from feature changes
- Prefer `jj commit` over `jj squash` — new commits over squashing.
  Only squash when the prior commit specifically needs fixing up
  (correcting a bug it introduced, fixing a typo in code it added).
- Proactively suggest committing once a logical chunk of work is done —
  don't wait for the user to ask

## Environment

Never work around the environment as configured. When a tool, path,
credential, or setting is missing or broken, stop and say so — don't
install a substitute, shim around it, or switch to a different tool to
get unblocked. Changing the configuration is my call.

## Learning log

When you discover something non-obvious during work — a gotcha,
undocumented behavior, or surprise that would change how you'd
approach similar work — invoke the `til` skill. It decides whether
the learning belongs in an existing skill, a new TIL file, or
nowhere.

When starting non-trivial work or stuck on tool/library behavior,
invoke `til` to surface relevant prior learnings before proceeding.

## Learning exercises

After architectural work — a new module, a schema change, a refactor,
an unfamiliar pattern — offer me a short learning exercise on it.

Keep the offer to one sentence and stop there; never start an exercise
before I say yes. Once I do, invoke the `learning-opportunities` skill
and let it own the rest — what kind of exercise, how to run it, and how
many to offer per session.

## Continuous improvement

When something slows you down mid-task, name it in a line or two at the
end of your turn. Report only friction you actually hit this turn, not
hypotheticals, and list at most one or two. If nothing got in your way,
say nothing — don't invent friction, and don't report its absence.

Friction worth naming:
- documentation that was wrong and cost extra debugging steps
- poor errors or diagnostics that don't give enough information to
  diagnose the problem
- noisy messages that fill the context window
- a workaround for a bad API that makes the code worse
- a step with no shortcuts, done by hand several times

Just name it — don't fix or file it unless asked. Don't pad the reply
or restate points already made; surface only what hasn't come up.

## Anti-rationalization

These conventions exist because LLMs skip steps when unsupervised.
If you catch yourself thinking any of these, stop — you're
rationalizing a shortcut:

- "This is simple enough to skip"
- "I already tested manually"
- "The spirit, not the letter"
- "This case is different"

Follow the process.
