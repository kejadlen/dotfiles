---
name: datadog-mcporter
description: Use when searching Datadog logs, metrics, traces, spans, dashboards, monitors, incidents, events, notebooks, services, hosts, or RUM events via mcporter CLI.
---

# Datadog

Observability and monitoring via mcporter. Prefix all calls with
`datadog.`. Run `mcporter list datadog --schema` for full tool details.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Tools

| Tool | Purpose |
|------|---------|
| `search_datadog_logs` | Raw log entries, pattern discovery, attribute exploration |
| `analyze_datadog_logs` | SQL analytics against logs (counts, group-by, aggregations) |
| `search_datadog_metrics` | List available metrics with optional filtering |
| `get_datadog_metric` | Fetch timeseries data for one or more metric queries |
| `get_datadog_metric_context` | Metadata, tags, and related assets for a metric |
| `search_datadog_spans` | Raw span inspection and attribute discovery |
| `aggregate_spans` | Aggregated span analysis (counts, averages, grouped) |
| `get_datadog_trace` | Fetch all spans in a specific trace by trace ID |
| `search_datadog_events` | Raw event inspection (titles, messages, tags) |
| `aggregate_events` | Aggregated event analysis (counts, sums, grouped) |
| `search_datadog_dashboards` | Find dashboards by title, metric, team, or author |
| `search_datadog_notebooks` | Find notebooks by keyword, author, or type |
| `get_datadog_notebook` | Fetch a full notebook by ID or URL |
| `create_datadog_notebook` | Create a notebook with markdown, metric, and log cells |
| `edit_datadog_notebook` | Edit or append to an existing notebook |
| `search_datadog_monitors` | Find monitors by title, status, team, or tag |
| `search_datadog_incidents` | Search incidents by state, severity, team |
| `get_datadog_incident` | Detailed incident info including timeline |
| `search_datadog_services` | List services by name or team |
| `search_datadog_service_dependencies` | Upstream/downstream service dependency graph |
| `search_datadog_hosts` | SQL queries against the hosts inventory |
| `search_datadog_rum_events` | Raw RUM event inspection |
| `aggregate_rum_events` | Aggregated RUM analysis |
| `check_datadog_mcp_setup` | Diagnose permission issues |

## Search vs. aggregate

Logs, events, spans, and RUM each have a `search_*` and an
`aggregate_*` tool. Use search first to inspect raw data and discover
fields, then aggregate for counts and summaries. Never use search
tools for counting or aggregation.

## DDSQL

`analyze_datadog_logs` and `search_datadog_hosts` run DDSQL, a
PostgreSQL subset. Key restrictions: non-aggregated SELECT columns
must appear in GROUP BY, SELECT aliases cannot be reused in
WHERE/GROUP BY/HAVING (repeat the expression), and column names with
`@` need quoting. No `ANY()`, `->>`, or `current_timestamp`.

## Gotchas

`search_datadog_service_dependencies`: supply either `service` or
`team`, not both. When using `service`, you must also set `direction`
to `upstream` or `downstream`.

Relative time values must start with `now-` (for `from`) or `now` (for
`to`). Defaults vary by tool.
