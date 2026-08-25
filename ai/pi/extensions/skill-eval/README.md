# Skill Eval

Three ways to judge a skill or `AGENTS.md` file, from cheapest to most
expensive. All three push toward a smaller file: efficacy is the bar every
change has to clear, and length is what gets optimized once it's cleared.

| Command | What it does | Cost |
|---------|--------------|------|
| `/skill-eval` or `/skill-eval triage` | Ranks in-context skills and `AGENTS.md` files by line count and 90-day usage from session logs | Free |
| `/skill-eval review <target>` | Queues the file's text into the conversation with a trim rubric | One turn |
| `/skill-eval run <skill>` | Runs the skill's `evals.yml` through nested `pi` processes | API credit |

Triage and review are also available to the model through the `skill_eval`
tool. Evals are not: they spend real money, so only you start them.

## Behavioral evals

Reviewing a skill asks a model whether the text *looks* right. An eval checks
what the text actually does, in two parts.

Trigger fidelity answers whether the `description` frontmatter makes the agent
reach for the skill. Each case runs a fresh `pi` with ordinary skill discovery
on — competing descriptions are part of the test — and only the `read` tool
available. A case passes when the run reads a file in the skill's directory
(positive cases) or leaves it alone (negative cases).

Instruction adherence answers whether the body changes behavior once loaded.
Each case forces the skill in with `/skill:<name>`, runs the task in a fresh
temporary directory, then hands the transcript to a second `pi` run that grades
every declared expectation as pass, fail, or unclear. A case passes only when
all of its expectations pass.

Runs use the model and thinking level of the session you launch them from, so
scores describe the setup you actually work in. Everything else is hermetic:
no session file, no extensions, no `AGENTS.md`, no prompt templates, and a
scratch working directory per case. Globally discovered skills are the one
exception, and they are deliberate.

## Writing evals.yml

Put `evals.yml` next to `SKILL.md`:

```yaml
trigger:
  positive:
    # Tasks the skill should be loaded for. Phrase them the way you would.
    - prompt: I need to squash this change into its parent
    - prompt: |
        The description of my last commit is wrong.
        Fix it.
      note: covers the describe-versus-commit distinction
  negative:
    # Nearby tasks the skill should stay out of.
    - prompt: Add fzf-git as a submodule with a shallow clone

adherence:
  - prompt: Commit the change in this repo
    expect:
      - runs `jj commit` rather than `jj describe`
      - the commit message subject is a plain sentence with no conventional-commit prefix
      - the message carries an `Assisted-by` trailer
    tools: [read, bash]
    setup: |
      jj git init
      echo "hello" > file.txt
```

Fields:

`trigger.positive` and `trigger.negative` take a list of cases. A case is
either a bare string or a mapping with `prompt` and an optional `note`.

`adherence` takes a list of mappings. `prompt` and `expect` are required;
`expect` holds one checkable claim per entry, since the judge grades each
separately. `tools` defaults to `[read]`, which keeps a case read-only and
grades what the agent says it would do; add `bash`, `edit`, or `write` when the
task only means something if the agent carries it out. `setup` is a bash script
run in the sandbox before the agent starts, for scaffolding fixtures.

A prompt cannot start with `-` or `@`, which `pi` reads as a flag or a file
include. Validation rejects those with the case's path, along with every other
problem in the file, so one run of the command surfaces all of them.

## Running

```
/skill-eval run jj
/skill-eval run jj --only trigger        # skip the expensive half
/skill-eval run jj --repeat 3            # attempts per case, to expose flakiness
/skill-eval run jj --jobs 1              # cases in flight at once (default 3)
/skill-eval run jj --case pitfall        # only cases whose prompt or note matches
/skill-eval run jj --case 'file show'    # quote a filter containing spaces
```

The command confirms the run count first. Trigger cases cost one model run
each; adherence cases cost two, because grading is its own run. Use `--case`
while authoring, so iterating on one case doesn't re-bill the ones that already
pass. A report lands in `$XDG_STATE_HOME/pi/skill-eval/reports/`.

Failures arrive as a follow-up message so the conversation can fix the text,
with the ask being to sharpen or cut what's there before adding anything. A
clean run over the whole suite arrives as a trim invitation instead: a green
suite is the safety net that makes cutting cheap, since you can cut, re-run,
and read a still-green score as proof the text wasn't load-bearing. Runs
narrowed by `--case` or `--only` skip the invitation, because they only prove
part of the suite.

The report also lists bundled reference files no run opened. That's the
cheapest trim signal the run produces, and it cuts both ways: either the file
isn't earning its place, or no case reaches the behavior it covers.

A report that opens with a provider-retry line is not a verdict on the skill.
Overload, rate limiting, or the five-minute per-run timeout can kill a nested
run before anything reaches the judge. Those cases report once as `run error`,
list their expectations as `ungraded` rather than `fail`, and print the tail of
the transcript under "Where it stopped" so you can tell a thrashing agent from
one that just ran out of clock. When every failure in a run is a dead run, the
follow-up asks for a re-run instead of edits — unproven is not disproven, and a
timeout says nothing about the text. Re-run with `--case` before believing any
of it.

`ungraded` and `unclear` are different: `ungraded` means no verdict exists,
while `unclear` means the judge read the transcript and it didn't settle the
expectation. Only the second is a signal about the skill.

Trigger misses usually mean the `description` field needs the vocabulary of the
prompt that missed. False positives on negative cases mean it claims too much
ground. Adherence failures point at the body: an instruction stated once in
passing, buried under prose, or contradicted elsewhere in the file.

Write adherence cases where the skill has to *overcome* something, not where it
merely agrees with the model. Asking whether a strong model can restate advice
it just read tells you little; asking it to do something its training says is
spelled differently tells you whether the skill lands. `ai/skills/jj/evals.yml`
is the worked example — its second half draws on `pitfalls.md`, where jj's real
behavior contradicts a git-shaped instinct.

## Layout

| File | Contents |
|------|----------|
| `index.ts` | Command and tool registration, triage, review, target resolution |
| `evals.ts` | `evals.yml` loading and validation |
| `subagent.ts` | Spawning nested `pi` processes and parsing their JSON event stream |
| `run.ts` | Case orchestration, judging, scoring, report and follow-up formatting |

Tests run without spending API credit; a stub entrypoint injected through
`PI_BIN` stands in for `pi`.

```bash
node --test "ai/pi/extensions/skill-eval/*.test.ts"
```
