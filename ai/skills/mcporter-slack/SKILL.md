---
name: mcporter-slack
description: Use when searching Slack, finding messages, sending messages, checking channel history, getting thread replies, listing channels, or getting user profiles via mcporter CLI.
---

# Slack via mcporter

Use the mcporter CLI to interact with Slack. Run commands via Bash.

## Syntax

```bash
mcporter call slack.<tool> key=value key2=value2
```

Timestamp parameters (`message_ts`, `thread_ts`, `oldest`, `latest`) are
typed as strings in the schema, but `key=value` syntax coerces them to
numbers. Use `--args` JSON for any call that includes timestamps:

```bash
mcporter call slack.slack_read_thread --args '{"channel_id":"C0ABC123","message_ts":"1772034831.268949"}'
```

## Available Tools

| Tool | Purpose |
|------|---------|
| `slack_search_public` | Search messages in public channels |
| `slack_search_public_and_private` | Search messages across all channels |
| `slack_search_channels` | Find channels by name |
| `slack_search_users` | Find users by name or email |
| `slack_read_channel` | Read messages from a channel |
| `slack_read_thread` | Read a thread (parent + replies) |
| `slack_read_user_profile` | Get a user's profile |
| `slack_send_message` | Send a message or thread reply |
| `slack_send_message_draft` | Draft a message for user review |
| `slack_schedule_message` | Schedule a message for later |

## Channel IDs

All tools take `channel_id`, not channel names. Look up the ID first:

```bash
mcporter call slack.slack_search_channels query="general"
```

ID formats: `C` + 10 chars for channels, `D` + 10 chars for DMs,
`G` + 10 chars for groups. Never pass user IDs (`U` + 10 chars) as
`channel_id` — look up the DM channel ID instead.

For private channels, the Slack MCP app must be invited to the channel.

## Common Mistakes

- Parentheses in OR queries silently fail. Write `from:@me OR to:@me`,
  not `(from:@me OR to:@me)`.
- Passing timestamps as `key=value` coerces them to numbers and fails
  schema validation. Use `--args` JSON instead.
- Sending to user IDs instead of channel IDs. Always resolve the channel
  ID through `slack_search_channels` or `slack_search_users` first.

## Search Queries

```bash
mcporter call slack.slack_search_public query="from:@user OR to:@user after:2025-01-01 before:2025-01-07"
mcporter call slack.slack_search_public query="from:@user on:2025-01-15"
```

Modifiers: `from:@user`, `to:@user`, `mentions:@user`, `in:#channel`,
`before:` / `after:` / `on:` with `YYYY-MM-DD` or `today`,
`is:thread`, `has:pin`.

## Common Workflows

### Find and Read a Conversation

```bash
# Search for messages
mcporter call slack.slack_search_public query="keyword in:#channel"

# Read a thread (use --args for timestamps)
mcporter call slack.slack_read_thread --args '{"channel_id":"C0ABC123","message_ts":"1234567890.123456"}'
```

### Browse a Channel

```bash
mcporter call slack.slack_read_channel channel_id=C0ABC123 limit=50
```

### Send Messages

```bash
# New message
mcporter call slack.slack_send_message channel_id=C0ABC123 message="Hello"

# Thread reply (use --args for timestamps)
mcporter call slack.slack_send_message --args '{"channel_id":"C0ABC123","message":"Reply","thread_ts":"1234567890.123456"}'

# Broadcast reply (also posts to channel)
mcporter call slack.slack_send_message --args '{"channel_id":"C0ABC123","message":"Reply","thread_ts":"1234567890.123456","reply_broadcast":true}'
```

## Timestamps

Slack timestamps look like `1234567890.123456` (Unix seconds with
microseconds). They appear as `ts`, `thread_ts`, or `message_ts` in
message objects. Always pass them as strings via `--args` JSON.
