---
name: slack-mcporter
description: Use when searching Slack, finding messages, sending messages, checking channel history, getting thread replies, listing channels, or getting user profiles via mcporter CLI.
---

# Slack

Official Slack MCP via mcporter. Tool names join to the server with a
dot: `mcporter call slack.<tool>` (e.g.
`mcporter call slack.slack_search_users query=alpha`). Run
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

**Always use `slack_send_message_draft` instead of `slack_send_message`.**
Drafts let the user review and edit before posting, and Slack treats
drafts as normal messages once sent — so they remain editable afterward.
Messages posted directly via MCP cannot be edited in Slack.

The `message` param takes standard markdown. Thread replies need
`thread_ts`; set `reply_broadcast=true` to also post to the channel.
Cannot post to Slack Connect channels.

**Links in drafts:** the draft composer renders everything as
plaintext — markdown `[text](url)`, Slack mrkdwn `<url|text>`, and even
bare URLs all show as plain text in the draft preview. Links resolve
only when the message is actually sent. Don't try to fix this by
changing link syntax; it's a draft-preview limitation. Use markdown
`[text](url)` (the documented format) for the best *sent* output, and
tell the user the preview won't show links but the sent message will.

### Drafting in Alpha's voice

When drafting on Alpha's behalf, match the "Writing voice" section in
the global CLAUDE.md, with fuller examples in
`ai/references/writing-style.md` in the dotfiles repo. Short, direct,
first person. Dashes for asides — not semicolons. Lowercase fragments
fine in DMs; full sentences in channels. No sign-offs. Backticks for
inline code. Link to threads, PRs, or messages rather than describing
them.

### Posting Claude's own findings to a thread

When Alpha asks to "update a thread" with *your* findings (research,
debugging, an investigation result) — as opposed to ghost-writing in his
voice — always:

1. Create it as a **draft** (`slack_send_message_draft`), never send directly.
2. **Attribute it to Claude** — lead with a `From Claude:` line.
3. Put the substance in a **quote or code block**, set off from the
   attribution line.

Shape:

```
From Claude:
> ...findings...
```

This is the opposite default from "Drafting in Alpha's voice": don't
ventriloquize his voice for these — mark them clearly as AI-authored so the
thread can tell the two apart, and so he can review/edit before sending.

## Timestamps

Slack message timestamps (`1234567890.123456`) appear as `ts`,
`thread_ts`, or `message_ts`. Always pass via `--args` JSON (see the
`mcporter` skill).
