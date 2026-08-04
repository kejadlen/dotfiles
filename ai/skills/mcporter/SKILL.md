---
name: mcporter
description: Use when calling MCP tools via the mcporter CLI — covers call syntax, argument formats, timestamp handling, and tool discovery.
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

## Discovering tools

```bash
mcporter list                    # List configured servers
mcporter list <server> --schema  # Show all tools with full parameter schemas
mcporter call --help             # Full call syntax
```
