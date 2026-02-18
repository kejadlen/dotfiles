#!/usr/bin/env bash
#
# dump-session.sh — Export a Claude Code session JSONL to readable Markdown.
#
# Usage:
#   dump-session.sh <session.jsonl|session-id> [output.md]
#
# The first argument can be a path to a JSONL file or a session UUID.
# When given a UUID, the script searches ~/.claude/projects/ for a matching file.
# If output.md is omitted, writes to stdout.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: dump-session.sh <session.jsonl|session-id> [output.md]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${2:-/dev/stdout}"

# Parse session JSONL into structured JSON, then format as Markdown.
"$SCRIPT_DIR/parse-session.sh" "$1" | jq -r '
  # Format conversation
  (.messages | map(
    if .role == "user" then
      "### User <sub>\(.timestamp)</sub>\n\n\(.content)\n"
    elif .role == "assistant" then
      ([.tools[] |
        "- **\(.name)**" +
        if .detail then " `\(.detail)`"
        else ""
        end
      ]) as $tool_lines |

      "### Assistant <sub>\(.timestamp)</sub>\n\n" +
      (if (.content | length) > 0 then .content + "\n\n" else "" end) +
      (if ($tool_lines | length) > 0 then
        "<details><summary>Tool calls</summary>\n\n" +
        ($tool_lines | join("\n")) +
        "\n\n</details>\n"
      else "" end)
    else ""
    end
  ) | map(select(. != "")) | join("\n")) as $conversation |

  # Format tool list
  (.tools | map("\(.name) (\(.count))") | join(" · ")) as $tool_list |

  # Assemble document — designed for GitHub PR descriptions.
  # Summary first (visible without expanding), conversation and metadata collapsed.
  "<!-- Replace this with a summary of the session -->\n\n" +
  "<details><summary>Session transcript</summary>\n\n" +
  $conversation + "\n\n" +
  "</details>\n\n" +
  "<details><summary>Session metadata</summary>\n\n" +
  "| Field | Value |\n|-------|-------|\n" +
  "| Session ID | `\(.meta.session_id)` |\n" +
  "| Claude Code | v\(.meta.version) |\n" +
  "| Directory | `\(.meta.cwd)` |\n" +
  "| Branch | `\(.meta.branch)` |\n" +
  "| Started | \(.meta.started) |\n" +
  "| Ended | \(.meta.ended) |\n" +
  "| Messages | \(.meta.user_count) user · \(.meta.assistant_count) assistant |\n" +
  "| Models | \(.meta.models) |\n" +
  "| Tools | \($tool_list) |\n\n" +
  "</details>\n"
' > "$OUTPUT"

if [[ "$OUTPUT" != "/dev/stdout" ]]; then
  echo "Exported to $OUTPUT" >&2
fi
