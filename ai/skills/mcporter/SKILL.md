---
name: mcporter
description: Use when calling MCP tools via the mcporter CLI — covers call syntax, argument formats, timestamp handling, detecting errors, and tool discovery.
---

# mcporter

CLI for calling MCP server tools. Run commands via Bash.

## Syntax

```bash
mcporter call <server>.<tool> key=value key2=value2
mcporter call <server>.<tool> --args '{"key":"value"}'
```

The server and tool are joined with a dot — `<server>.<tool>`, not two
space-delimited words.

```bash
# Wrong — space instead of a dot between server and tool.
mcporter call slack slack_send_message channel_id=C123 message=hi

# Right.
mcporter call slack.slack_send_message channel_id=C123 message=hi
```

Both `key=value` and `--args` JSON work. Prefer `key=value` for simple
calls. Use `--args` JSON when any parameter is a string that looks
numeric — `key=value` coerces values, which breaks schema validation
for string-typed fields like timestamps.

```bash
# key=value coerces 1772034831.268949 to a number — fails validation.
mcporter call slack.get_thread_messages channel=general thread_ts=1772034831.268949

# --args preserves the string type.
mcporter call slack.get_thread_messages --args '{"channel":"general","thread_ts":"1772034831.268949"}'
```

## Errors

`mcporter call` exits 0 when the upstream server returns an error, so a
script can't trust `$?`. The failure shows up in the payload instead —
an `APIResponseError` with `code` and `status` keys, and the readable
message nested in `body` as a JSON string:

```bash
resp=$(mcporter call notion.notion-query-data-sources --args "$args")
if [[ $(jq -r 'has("code") and has("status")' <<<"$resp") == true ]]; then
    jq -r '(try (.body | fromjson | .message)) // .code' <<<"$resp" >&2
    exit 1
fi
```

Write calls can also outrun the default 60 s timeout — pass
`--timeout 120000` or set `MCPORTER_CALL_TIMEOUT=120000`.

## Discovering tools

```bash
mcporter list                    # List configured servers
mcporter list <server> --schema  # Show all tools with full parameter schemas
mcporter call --help             # Full call syntax
```
