#!/usr/bin/env bash
#
# parse-session.sh — Parse a Claude Code session JSONL into structured JSON.
#
# Usage:
#   parse-session.sh <session.jsonl|session-id> [output.json]
#
# The first argument can be a path to a JSONL file or a session UUID.
# When given a UUID, the script searches ~/.claude/projects/ for a matching file.
# If output.json is omitted, writes to stdout.
#
# Requires: jq 1.6+

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: parse-session.sh <session.jsonl|session-id> [output.json]" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-/dev/stdout}"

# Resolve input: file path or session UUID
if [[ -f "$INPUT" ]]; then
  SESSION_FILE="$INPUT"
elif [[ "$INPUT" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
  SESSION_FILE=$(find ~/.claude/projects -name "${INPUT}.jsonl" -print -quit 2>/dev/null)
  if [[ -z "$SESSION_FILE" ]]; then
    echo "Error: No session file found for ID: $INPUT" >&2
    exit 1
  fi
else
  echo "Error: Not a file path or valid session UUID: $INPUT" >&2
  exit 1
fi

jq -rs '
  (map(select(.type == "user"))) as $users |
  (map(select(.type == "assistant"))) as $assistants |
  (map(select(.type == "user" or .type == "assistant"))) as $messages |

  ($users[0] // {}) as $first |

  # Tool usage counts
  ([
    $assistants[].message.content[]? |
    select(type == "object" and .type == "tool_use") | .name
  ] | group_by(.) | map({name: .[0], count: length}) | sort_by(-.count)) as $tools |

  # Build messages array
  ($messages | map(
    if .type == "user" then
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

      (.message.content |
        if type == "array" then all(type == "object" and .type == "tool_result")
        else false
        end
      ) as $is_tool_result_only |

      ($content | test("^<(command-name|local-command|system-reminder)")) as $is_system |

      ($content | test("^Base directory for this skill:")) as $is_skill |

      if $is_tool_result_only or $is_system or ($content | length) == 0 then
        null
      else
        {role: "user", timestamp: (.timestamp // ""), content: $content, tools: [],
         kind: (if $is_skill then "skill" else "message" end)}
      end

    elif .type == "assistant" then
      ([.message.content[]? | select(type == "object" and .type == "text") | .text] | join("\n\n")) as $text |

      ([.message.content[]? | select(type == "object" and .type == "tool_use") |
        {
          name: .name,
          detail: (
            if .input.command then (.input.command | tostring | split("\n") | .[0])
            elif .input.pattern then .input.pattern
            elif .input.file_path then .input.file_path
            else null
            end
          )
        }
      ]) as $tool_list |

      if ($text | length) == 0 and ($tool_list | length) == 0 then
        null
      else
        {role: "assistant", timestamp: (.timestamp // ""), content: $text, tools: $tool_list,
         kind: "message"}
      end
    else null
    end
  ) | map(select(. != null))) as $msg_list |

  {
    meta: {
      session_id: ($first.sessionId // "unknown"),
      version: ($first.version // "unknown"),
      cwd: ($first.cwd // "unknown"),
      branch: ($first.gitBranch // "unknown"),
      started: ($messages | first | .timestamp // ""),
      ended: ($messages | last | .timestamp // ""),
      user_count: ($users | length),
      assistant_count: ($assistants | length),
      models: ([$assistants[].message.model // empty] | unique | join(", "))
    },
    tools: $tools,
    messages: $msg_list
  }
' "$SESSION_FILE" > "$OUTPUT"
