---
name: slack
description: Use when searching Slack, finding messages, sending messages, checking channel history, getting thread replies, listing channels, or getting user profiles via mcporter CLI.
---

# Slack

Slack tools via mcporter. Prefix all calls with `slack.`.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Available tools

| Tool | Purpose |
|------|---------|
| `search` | Search messages across all channels (public, private, DMs) |
| `list_channels` | List all channels in the workspace |
| `get_channel` | Get channel details (name, purpose, topic, member count) |
| `get_channel_history` | Read recent messages from a channel |
| `get_thread_messages` | Read a thread (parent + replies) |
| `fetch` | Fetch a specific message by channel and timestamp |
| `get_conversation_members` | List user IDs in a channel |
| `list_users` | List all users in the workspace |
| `get_profile` | Get a user's profile by username or user ID |
| `get_team_info` | Get workspace/team information |
| `list_usergroups` | List user groups (@engineering, etc.) |
| `get_usergroup_members` | Get members of a user group |
| `send_message` | Send a message or thread reply |
| `get_reactions` | Get emoji reactions on a message |
| `add_reaction` | Add an emoji reaction to a message |

Run `mcporter list slack --schema` if a tool's parameters aren't
listed here.

## Channels

Most tools accept a `channel` parameter that takes either a channel
name (`general`, `#general`) or a channel ID (`C1234567890`). Channel
names are resolved automatically.

For private channels, the Slack MCP app must be invited to the channel.

## Search queries

```bash
mcporter call slack.search query="from:user OR to:user after:2025-01-01 before:2025-01-07"
mcporter call slack.search query="from:user on:2025-01-15"
```

Modifiers: `from:user`, `to:user`, `mentions:user`, `in:#channel`,
`before:` / `after:` / `on:` with `YYYY-MM-DD` or `today`,
`is:thread`, `has:pin`.

Optional parameters: `count` (default 20, max 100), `sort` (`score`
or `timestamp`), `sort_dir` (`asc` or `desc`).

## Common workflows

### Find and read a conversation

```bash
mcporter call slack.search query="keyword in:#channel"
mcporter call slack.get_thread_messages --args '{"channel":"C0ABC123","thread_ts":"1234567890.123456"}'
```

### Browse a channel

```bash
mcporter call slack.get_channel_history channel=general limit=50
```

### Fetch a specific message

```bash
mcporter call slack.fetch --args '{"channel":"general","ts":"1234567890.123456"}'
```

### Send messages

```bash
# New message.
mcporter call slack.send_message channel=general text="Hello"

# Thread reply.
mcporter call slack.send_message --args '{"channel":"C0ABC123","text":"Reply","thread_ts":"1234567890.123456"}'

# Broadcast reply (also posts to channel).
mcporter call slack.send_message --args '{"channel":"C0ABC123","text":"Reply","thread_ts":"1234567890.123456","reply_broadcast":true}'
```

### React to a message

```bash
mcporter call slack.add_reaction --args '{"channel":"general","timestamp":"1234567890.123456","name":"thumbsup"}'
```

## Timestamps

Slack timestamps look like `1234567890.123456` (Unix seconds with
microseconds). They appear as `ts`, `thread_ts`, or `message_ts` in
message objects. Always pass them via `--args` JSON (see the `mcporter`
skill for why).

## Common mistakes

- The `@` prefix on `from:` and `to:` modifiers doesn't work reliably.
  Use bare names: `from:me to:martin.emde`, not `from:@me to:@Martin Emde`.
- Parentheses in OR queries silently fail. Write `from:me OR to:me`,
  not `(from:me OR to:me)`.
- Using `message` instead of `text` in `send_message`. The parameter
  is `text`.
