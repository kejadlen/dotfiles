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

INPUT="$1"
OUTPUT="${2:-/dev/stdout}"

# Resolve input: file path or session UUID
if [[ -f "$INPUT" ]]; then
  SESSION_FILE="$INPUT"
elif [[ "$INPUT" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
  # Search all project dirs for a matching JSONL
  SESSION_FILE=$(find ~/.claude/projects -name "${INPUT}.jsonl" -print -quit 2>/dev/null)
  if [[ -z "$SESSION_FILE" ]]; then
    echo "Error: No session file found for ID: $INPUT" >&2
    exit 1
  fi
else
  echo "Error: Not a file path or valid session UUID: $INPUT" >&2
  exit 1
fi

# Single jq invocation: slurp all lines and produce the full markdown.
jq -rs '
  # Partition by type
  (map(select(.type == "user"))) as $users |
  (map(select(.type == "assistant"))) as $assistants |
  (map(select(.type == "user" or .type == "assistant"))) as $messages |

  # Metadata from first user message
  ($users[0] // {}) as $first |
  ($first.sessionId // "unknown") as $session_id |
  ($first.version // "unknown") as $version |
  ($first.cwd // "unknown") as $cwd |
  ($first.gitBranch // "unknown") as $branch |

  # Time range
  ($messages | first | .timestamp // "") as $first_ts |
  ($messages | last | .timestamp // "") as $last_ts |

  # Models
  ([$assistants[].message.model // empty] | unique | join(", ")) as $models |

  # Tool usage counts
  ([
    $assistants[].message.content[]? |
    select(type == "object" and .type == "tool_use") | .name
  ] | group_by(.) | map({name: .[0], count: length}) | sort_by(-.count)) as $tools |

  # Format tool list
  ($tools | map("- \(.name) (\(.count))") | join("\n")) as $tool_list |

  # Format conversation
  ($messages | map(
    if .type == "user" then
      # Extract content
      (.message.content |
        if type == "string" then .
        elif type == "array" then
          [.[] |
            if type == "string" then .
            elif .type == "text" then .text
            elif .type == "tool_result" then null
            else null
            end
          ] | map(select(. != null)) | join("\n\n")
        else ""
        end
      ) as $content |

      # Check if tool_result-only
      (.message.content |
        if type == "array" then all(type == "object" and .type == "tool_result")
        else false
        end
      ) as $is_tool_result_only |

      # Check if system/command message
      ($content | test("^<(command-name|local-command|system-reminder)")) as $is_system |

      if $is_tool_result_only or $is_system or ($content | length) == 0 then
        null
      else
        "### User <sub>\(.timestamp // "")</sub>\n\n\($content)\n"
      end

    elif .type == "assistant" then
      # Text blocks
      ([.message.content[]? | select(type == "object" and .type == "text") | .text] | join("\n\n")) as $text |

      # Tool use summary
      ([.message.content[]? | select(type == "object" and .type == "tool_use") |
        "- **\(.name)**" +
        if .input.command then " `\(.input.command | tostring | split("\n") | .[0])`"
        elif .input.pattern then " `\(.input.pattern)`"
        elif .input.file_path then " `\(.input.file_path)`"
        else ""
        end
      ]) as $tool_lines |

      if ($text | length) == 0 and ($tool_lines | length) == 0 then
        null
      else
        "### Assistant <sub>\(.timestamp // "")</sub>\n\n" +
        (if ($text | length) > 0 then $text + "\n\n" else "" end) +
        (if ($tool_lines | length) > 0 then
          "<details><summary>Tool calls</summary>\n\n" +
          ($tool_lines | join("\n")) +
          "\n\n</details>\n"
        else "" end)
      end
    else null
    end
  ) | map(select(. != null)) | join("\n")) as $conversation |

  # Assemble document
  "# Session Export\n\n" +
  "## Metadata\n\n" +
  "| Field | Value |\n|-------|-------|\n" +
  "| Session ID | `\($session_id)` |\n" +
  "| Claude Code | v\($version) |\n" +
  "| Working directory | `\($cwd)` |\n" +
  "| Branch | `\($branch)` |\n" +
  "| Started | \($first_ts) |\n" +
  "| Ended | \($last_ts) |\n" +
  "| User messages | \($users | length) |\n" +
  "| Assistant messages | \($assistants | length) |\n" +
  "| Models | \($models) |\n\n" +
  "## Tools Used\n\n\($tool_list)\n\n---\n\n" +
  "## Summary\n\n<!-- Replace this with a summary of the session -->\n\n---\n\n" +
  "## Conversation\n\n\($conversation)\n"
' "$SESSION_FILE" > "$OUTPUT"

if [[ "$OUTPUT" != "/dev/stdout" ]]; then
  echo "Exported to $OUTPUT" >&2
fi
