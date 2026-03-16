---
name: slack-mcporter
description: Use when searching Slack, finding messages, sending messages, checking channel history, getting thread replies, listing channels, or getting user profiles via mcporter CLI.
---

# Slack

Slack tools via mcporter. Prefix all calls with `slack.`. Run
`mcporter list slack --schema` for the full tool list and parameters.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Channels

Most tools accept `channel` as a name (`general`) or ID (`C1234567890`).
Private channels require the Slack MCP app to be invited.

## Search

```bash
mcporter call slack.search query="from:user OR to:user after:2025-01-01 before:2025-01-07"
```

Modifiers: `from:`, `to:`, `mentions:`, `in:#channel`, `before:`,
`after:`, `on:` (YYYY-MM-DD or `today`), `is:thread`, `has:pin`.

Optional: `count` (default 20, max 100), `sort` (`score`/`timestamp`),
`sort_dir` (`asc`/`desc`).

## Timestamps

Slack timestamps (`1234567890.123456`) appear as `ts`, `thread_ts`, or
`message_ts`. Always pass via `--args` JSON (see the `mcporter` skill).

## Common mistakes

- Bare names in search modifiers: `from:me`, not `from:@me`.
- No parentheses in OR queries: `from:me OR to:me`, not
  `(from:me OR to:me)` (silently returns zero results).
- `send_message` uses `text`, not `message`.
