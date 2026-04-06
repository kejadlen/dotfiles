---
name: granola-mcporter
description: Use when querying meeting notes, listing meetings, getting meeting details or transcripts, or browsing meeting folders via Granola and mcporter CLI.
---

# Granola

Meeting notes and transcripts via mcporter. Prefix all calls with
`granola.`. Run `mcporter list granola --schema` for full tool details.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Tools

| Tool | Purpose |
|------|---------|
| `query_granola_meetings` | Natural language queries about meeting content — the primary tool |
| `list_meetings` | List meetings within a time range, optionally filtered by folder |
| `get_meetings` | Fetch detailed info for specific meetings by ID (max 10) |
| `get_meeting_transcript` | Fetch the verbatim transcript for a single meeting |
| `list_meeting_folders` | List all folders with their IDs and note counts |

## Choosing the right tool

Start with `query_granola_meetings` for open-ended questions about
what was discussed, decided, or assigned. Use `list_meetings` +
`get_meetings` when you need structured metadata or browsing by date.
Use `get_meeting_transcript` only for exact quotes.

## Citations

`query_granola_meetings` returns inline citation links
(`[[0]](url)`) that reference source meeting notes. Always preserve
these in your output so the user can verify.
