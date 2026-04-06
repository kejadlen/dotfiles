---
name: glean-mcporter
description: Use when searching company knowledge, looking up documents, finding employees, searching code, checking Gmail, looking up meetings, reading URLs, checking user activity, or querying Glean memory via mcporter CLI.
---

# Glean

Company knowledge search via mcporter. Prefix all calls with `glean.`.
Run `mcporter list glean --schema` for full tool details.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Tools

| Tool | Purpose |
|------|---------|
| `search` | Primary tool for finding documents across all company apps |
| `chat` | AI-powered synthesis for complex questions needing analysis across sources |
| `code_search` | Search internal company code repos and private commits |
| `employee_search` | Find people by name, team, role, or reporting chain |
| `gmail_search` | Search Gmail inbox for emails, threads, and attachments |
| `meeting_lookup` | Search calendar meetings and extract transcripts |
| `read_document` | Fetch full content of one or more URLs (internal or external) |
| `read_memory` | Access the user's long-term work memories and personalization |
| `user_activity` | Retrieve document activity within a date range (`start_date` inclusive, `end_date` exclusive) |

## Search

Use `search` for keyword document retrieval, `chat` for interpretation
and synthesis. When in doubt, start with `search`.

Queries must be short, targeted keywords — not full sentences. No
boolean logic (OR/AND), no synonyms, no query stuffing. Do not use
date filters when the user says "latest" without a specific timeframe.

## Gotchas

`employee_search`: the `reportsto:` filter finds direct reports *of* a
person — do not use it to find who someone reports *to*.

`meeting_lookup`: time ranges are non-inclusive. To include all
meetings on a date, add buffer days (`after:2026-04-06
before:2026-04-08` for April 7). Date math uses no spaces:
`today-1d`, `now-2w`. Spaced expressions do not work.

`read_document`: results are all-or-nothing per URL. Do not retry the
same URL — results will be identical.
