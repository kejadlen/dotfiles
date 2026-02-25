---
name: mcporter-slack
description: Use when searching Slack, finding messages, sending messages, checking channel history, getting thread replies, adding reactions, listing channels, or getting user profiles via mcporter CLI.
---

# Slack via mcporter

Use the mcporter CLI to interact with Slack. Run commands via Bash.

## Syntax

```bash
mcporter call slack.<tool> key=value key2=value2
```

Use `key=value` flag-style arguments — no quoting of parentheses needed.

## Common Mistakes

- **Parentheses in OR queries silently fail.** `(from:@me OR to:@me)` returns 0 results. Write `from:@me OR to:@me` without parentheses.
- **Emoji colons in reactions.** Use `thumbsup` not `:thumbsup:`.

## Search Queries

### Date Ranges

```bash
mcporter call slack.search query="from:@user OR to:@user after:2025-01-01 before:2025-01-07"
```

### Single Day

```bash
mcporter call slack.search query="from:@user on:2025-01-15"
mcporter call slack.search query="from:@user on:today"
```

### Modifiers

- `from:@username` - messages sent by user
- `to:@username` - DMs to user
- `mentions:@username` - messages mentioning user
- `in:#channel` - messages in specific channel
- `before:YYYY-MM-DD` / `after:YYYY-MM-DD` - date bounds
- `on:YYYY-MM-DD` or `on:today` - single day

## Common Workflows

### Find and Read a Conversation

```bash
# Search for messages
mcporter call slack.search query="keyword in:#channel"

# Get full thread from a result
mcporter call slack.get_thread_messages channel="#channel" thread_ts=1234567890.123456

# Fetch specific message with replies
mcporter call slack.fetch channel="#channel" ts=1234567890.123456
```

### Browse a Channel

```bash
# Get channel info
mcporter call slack.get_channel channel="#general"

# Get recent messages
mcporter call slack.get_channel_history channel="#general" limit=50
```

### Send Messages

```bash
# New message
mcporter call slack.send_message channel="#channel" text="Hello"

# Thread reply
mcporter call slack.send_message channel="#channel" text="Reply" thread_ts=1234567890.123456

# Broadcast reply (also posts to channel)
mcporter call slack.send_message channel="#channel" text="Reply" thread_ts=1234567890.123456 reply_broadcast=true
```

### React to Messages

```bash
mcporter call slack.add_reaction channel="#channel" timestamp=1234567890.123456 name=thumbsup
```

## Timestamps

Slack uses Unix timestamps with microseconds (e.g., `1234567890.123456`). These appear as `ts` or `thread_ts` in message objects.
