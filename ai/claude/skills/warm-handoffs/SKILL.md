---
name: warm-handoff
description: Use when the user asks to "warm handoff", "/warm-handoff", "hand off this thread", or "redirect this to". Reads a Slack thread and proposes a warm handoff message for the target channel.
argument-hint: <slack-thread-url> <#target-channel>
---

# Warm Handoff

Compose a warm handoff message that carries a question from one Slack channel to another, with the person and context intact.

Source: https://luckymike.dev/posts/warm-handoffs/

## Arguments

`$ARGUMENTS` — a Slack thread URL and a target channel (e.g., `https://company.slack.com/archives/C01ABC/p1234567890 #team-accounts`)

## Workflow

1. **Parse the Slack link.** Extract the channel ID and message timestamp from the URL.
   - URL format: `https://<workspace>.slack.com/archives/<channel-id>/p<timestamp>`
   - The timestamp in the URL has no dot — insert a dot before the last 6 digits to get the Slack `ts` (e.g., `p1234567890123456` → `1234567890.123456`)

2. **Fetch the thread.** Use mcporter to read the thread:
   ```bash
   mcporter call slack.get_thread_messages channel="<channel-id>" thread_ts="<ts>"
   ```
   If there are no thread replies, fetch the single message:
   ```bash
   mcporter call slack.fetch channel="<channel-id>" ts="<ts>"
   ```

3. **Understand the question.** Identify:
   - Who is asking (mention them by name with `@`)
   - What they need help with
   - Any relevant details or context from the thread

4. **Draft the handoff message.** Write a message for the target channel that:
   - Links to the original thread
   - Tags the person who asked
   - Explains what they need and why this channel is the right place
   - Includes any additional context that would help the receiving team answer quickly
   - Is written from the perspective of the person doing the handoff (the user)

   Keep it concise — one short paragraph is ideal. Tone: collegial, helpful, direct.

   Example:
   > Hey folks! @Andre came to us with a question about 429s on `/v2/bulk-update`. I believe your team owns that endpoint. I checked the gateway metrics and see IP rate limiting but no client rate limiting — could be a missing `client_id`. Thread: [link]

5. **Present the draft.** Show the proposed message and the target channel. Ask the user to confirm or revise before sending.

6. **Send on confirmation.** Once approved:
   ```bash
   mcporter call slack.send_message channel="#target-channel" text="..."
   ```

## Principles

- **Carry the person** — tag them so they're part of the conversation, not starting over.
- **Carry the context** — summarize the question and add anything you know. The receiving team shouldn't have to ask "what's this about?"
- **Link the original** — so anyone can read the full thread if they need more detail.
- **Don't just redirect** — a cold redirect ("try #other-channel") is what we're replacing.
