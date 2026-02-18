---
name: dump-session
description: This skill should be used when the user asks to "dump session", "export session", "save session", "/dump-session", "export conversation", "save this conversation", or "write session to markdown". Exports the current Claude Code session as Markdown and HTML files with a summary.
---

# Dump Session

Export the current Claude Code session as Markdown and HTML files in the
repository, with a generated summary at the top and the full conversation below.

## Workflow

1. Identify the current session JSONL file
2. Run the Markdown export script
3. Run the HTML export script
4. Read the exports and write summaries to replace the placeholders
5. Review the exports for sensitive content and propose redactions
6. Save both files to the repository

## Identifying the Session

The user may specify which session to export by passing a session UUID or a file
path as an argument. When provided, use that value directly and skip
auto-detection.

When no argument is given, find the current session automatically. Claude Code
stores sessions as JSONL files under `~/.claude/projects/`. The project
directory name is the working directory path with slashes and dots replaced by
dashes, prefixed with a dash:

```
~/.claude/projects/-Users-alpha-chen-src-project-name/
```

To find the current session file, identify the most recently modified `.jsonl`
in the project directory. Run:

```bash
ls -t ~/.claude/projects/<project-dir>/*.jsonl | head -1
```

Derive `<project-dir>` from the current working directory by replacing `/` and
`.` with `-`.

## Running the Export

Use the bundled script to convert the JSONL to Markdown:

```bash
~/.claude/skills/dump-session/scripts/dump-session.sh <session.jsonl|session-id> <output.md>
```

The first argument accepts either a path to a JSONL file or a session UUID. When
given a UUID, the script searches `~/.claude/projects/` for a matching file.

The script produces a Markdown document designed for GitHub PR descriptions:

- A summary placeholder at the top (visible without expanding)
- The full conversation in a collapsible `<details>` block
- Session metadata (IDs, timestamps, tools) in a second collapsible block

## Writing the Summary

After the script runs, read the output file and replace the summary placeholder
with a concise summary of the session. The summary should cover what was
discussed, what was built or changed, and key decisions made. Write it in first
person to match the user's voice.

Replace:

```markdown
<!-- Replace this with a summary of the session -->
```

With the actual summary text.

## Redaction Review

After writing the summary, scan the full export for sensitive content that
should not be shared. Present each finding to the user with `AskUserQuestion`
and let them decide what to redact.

Common categories to flag:

- API keys, tokens, passwords, and credentials
- `<system-reminder>` content that leaked into visible messages (instructions,
  skill listings, CLAUDE.md contents)
- Absolute filesystem paths that reveal machine or user directory structure
- Internal hostnames, IP addresses, or URLs not meant to be public
- Personal information (emails, phone numbers, employee IDs) that appeared in
  tool output or conversation

For each finding, show the surrounding context and propose a replacement such as
`[REDACTED]` or a descriptive placeholder like `[API_KEY]`. Apply only the
redactions the user approves.

If nothing sensitive is found, tell the user and move on.

## HTML Generation

After the Markdown file is finalized (summary written, redactions applied),
generate a self-contained HTML thread view from the same session:

```bash
~/.claude/skills/dump-session/scripts/dump-session-html.sh <session.jsonl|session-id> <output.html>
```

The HTML script produces a chat-style page with user and assistant messages,
collapsed tool calls, collapsed skill content, metadata header, and a summary
placeholder. It uses pandoc to render markdown within messages. The output
includes inline CSS with dark/light mode support.

After generating, replace the HTML summary placeholder the same way as the
Markdown file. The summary `<div>` contains an HTML comment to replace.

## Output Location

Save both files to `docs/sessions/` in the repository root, creating the
directory if needed. Name them with the date and a slug derived from the session
topic:

```
docs/sessions/YYYY-MM-DD-topic-slug.md
docs/sessions/YYYY-MM-DD-topic-slug.html
```

## Scripts

- `scripts/parse-session.sh` — Parses a session JSONL file into structured
  JSON (metadata, tool counts, filtered messages). Both formatters depend on
  this script. Requires `jq` 1.6+.
- `scripts/dump-session.sh` — Converts the intermediate JSON from
  `parse-session.sh` into Markdown. Requires `jq` 1.6+.
- `scripts/dump-session-html.sh` — Converts the intermediate JSON from
  `parse-session.sh` into a self-contained HTML thread view. Requires `jq`
  1.6+ and `pandoc`.
