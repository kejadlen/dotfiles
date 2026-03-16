---
name: slack-mcporter
description: Use when searching Slack, finding messages, sending messages, checking channel history, getting thread replies, listing channels, or getting user profiles via mcporter CLI.
---

# Slack

Official Slack MCP via mcporter. Prefix all calls with `slack.`. Run
`mcporter list slack --schema` for full tool details.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Tools

| Tool | Purpose |
|------|---------|
| `slack_send_message` | Send to a channel or DM (use user_id as channel_id for DMs) |
| `slack_send_message_draft` | Create a draft for user review before sending |
| `slack_schedule_message` | Schedule a message (`post_at` is a Unix timestamp) |
| `slack_search_public` | Search public channels only |
| `slack_search_public_and_private` | Search public and private channels |
| `slack_search_channels` | Find channels by name |
| `slack_search_users` | Find users by name or email |
| `slack_read_channel` | Read channel history |
| `slack_read_thread` | Read thread replies (requires `channel_id` + `message_ts`) |
| `slack_read_user_profile` | Look up a user profile (defaults to current user) |
| `slack_create_canvas` | Create a canvas |
| `slack_update_canvas` | Append, prepend, or replace canvas content |
| `slack_read_canvas` | Read a canvas |

## Search

Two search tools: `slack_search_public` for public channels only,
`slack_search_public_and_private` for both. Query syntax:

```
from:<@User> in:#channel important topic
```

The `after` and `before` params take **Unix timestamps**, not date
strings. Use `sort` (`score`/`timestamp`) and `sort_dir` (`asc`/`desc`)
to control ordering. Max 20 results per call; paginate with `cursor`.

## IDs

Most tools require channel and user IDs, not names. Look them up first
with `slack_search_channels` and `slack_search_users`.

## Sending messages

Use `slack_send_message_draft` when the user hasn't reviewed the
message content. The `message` param takes standard markdown. Thread
replies need `thread_ts`; set `reply_broadcast=true` to also post to
the channel. Cannot post to Slack Connect channels.

## Timestamps

Slack message timestamps (`1234567890.123456`) appear as `ts`,
`thread_ts`, or `message_ts`. Always pass via `--args` JSON (see the
`mcporter` skill).
