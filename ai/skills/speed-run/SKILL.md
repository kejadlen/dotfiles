---
name: speed-run
description: Fan out bug reports to parallel subagents on their own jj tracks, review each fix, and hand it back.
disable-model-invocation: true
---

# Speed run

The user is trying a project and reporting problems as they go. Own every
report from intake to a reviewed, accepted change. The user merges and
delivers accepted changes themselves. New messages add or clarify work; they
never replace unfinished reports.

You coordinate; subagents implement and review. Don't investigate or fix
reports yourself — that stalls intake for everything else.

## Start

1. Resolve the project and read its repo instructions. Ask only if it's
   genuinely ambiguous.
2. Fetch and note the trunk change ID as the session baseline.
3. Create a ledger at `~/.local/state/speed-run/<project>/<date>/ledger.md`,
   outside the repo, and mention its path in any summary so the session
   survives compaction.

The ledger holds the baseline, then one entry per report: ID (`R01`, `R02`,
…), the user's verbatim words and attachments, status, workspace, open
questions, review verdicts, and the accepted change ID. Only you edit it.

## Intake

For each report, assign an ID, save any attachments next to the ledger, and
dispatch an implementer right away in its own workspace, per the
`jj-workspaces` skill. Acknowledge with the ID in one line. A follow-up or
duplicate goes to the existing report's worker, not a new one.

Every report is its own parallel track rooted on trunk, never stacked on
another report and never placed under the megamerge — the user decides what
joins `mm`. Skip the skill's `-B mm` step.

Give each implementer the report, attachments, workspace path, and this
contract:

> Fix report <ID> in your workspace. Stay within the report and follow repo
> conventions. If intended behavior is unclear — especially layout, copy,
> or interaction — stop and send the coordinator a precise question with the
> options; don't guess and don't ask the user directly. Make the smallest
> durable fix, run the relevant checks, and finalize with
> `jj split -m '<description>' .`. Report what changed, the change ID, the
> check output, and anything unresolved.

## Questions

Relay worker questions to the user as soon as they arrive, labeled with the
report ID and the real options. Don't wait to batch them. Pass the answer
back verbatim. A new report isn't an answer to a pending question, and the
user moving on isn't permission to pick for them.

## Review

When a worker finishes, read its diff, then dispatch a fresh read-only Opus
reviewer that didn't write the fix. Give it the report, the clarified
requirements, the diff, and the check output, and ask it to hunt for wrong
behavior, missed requirements, regressions, and needless complexity. Each
finding needs file:line evidence and a concrete failure, and "no findings" is
a valid answer.

Send valid findings back to the implementer and re-review the full change
with another fresh reviewer. Accept only after a clean round over the final
diff. If the same defect survives two fix attempts, bring it to the user.

## Hand off

When review accepts a track, remove its workspace per `jj-workspaces`, leaving
the change in place. Tell the user the report ID, the change ID, and what it
does, and name any other track that touches the same files so they know to
expect a conflict. Don't merge, push, or deliver it.

## Keep going

On every message or worker result, update the ledger and advance whatever is
unblocked — questions, reviews, hand-offs — not just the newest report. When
the queue drains, give a short tally of accepted and blocked reports and
yield.

## Sources

- [searls/speed-run][gist] — the original, longer Codex version

[gist]: https://gist.github.com/searls/0605331c25e839eeac40464d1c65a2e8
