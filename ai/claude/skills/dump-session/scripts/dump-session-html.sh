#!/usr/bin/env bash
#
# dump-session-html.sh — Export a Claude Code session JSONL to a self-contained HTML file.
#
# Usage:
#   dump-session-html.sh <session.jsonl|session-id> [output.html]
#
# The first argument can be a path to a JSONL file or a session UUID.
# When given a UUID, the script searches ~/.claude/projects/ for a matching file.
# If output.html is omitted, writes to stdout.
#
# Requires: jq 1.6+, pandoc

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: dump-session-html.sh <session.jsonl|session-id> [output.html]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${2:-/dev/stdout}"

# Parse session JSONL into structured JSON.
JSON=$("$SCRIPT_DIR/parse-session.sh" "$1")

# Convert markdown content to HTML fragments via pandoc.
# Iterates over each message, converts content, and reassembles.
MESSAGES_HTML=$(echo "$JSON" | jq -r '.messages[] | @base64' | while read -r encoded; do
  msg=$(echo "$encoded" | base64 --decode)
  role=$(echo "$msg" | jq -r '.role')
  timestamp=$(echo "$msg" | jq -r '.timestamp')
  content=$(echo "$msg" | jq -r '.content')
  tools=$(echo "$msg" | jq -c '.tools')
  kind=$(echo "$msg" | jq -r '.kind // "message"')

  # Convert markdown content to HTML
  if [[ -n "$content" ]]; then
    content_html=$(echo "$content" | pandoc -f markdown+raw_html -t html)
  else
    content_html=""
  fi

  # Build tool call HTML
  tools_html=""
  tool_count=$(echo "$tools" | jq 'length')
  if [[ "$tool_count" -gt 0 ]]; then
    tools_html=$(echo "$tools" | jq -r '.[] |
      "<div class=\"tool-call\">" +
      "<span class=\"tool-name\">" + .name + "</span>" +
      (if .detail then " <code>" + (.detail | gsub("<"; "&lt;") | gsub(">"; "&gt;")) + "</code>" else "" end) +
      "</div>"
    ')
  fi

  # Skip empty assistant messages
  if [[ "$role" == "assistant" && -z "$content_html" && "$tool_count" -eq 0 ]]; then
    continue
  fi

  # Emit the message HTML
  if [[ "$role" == "user" && "$kind" == "skill" ]]; then
    # Extract skill name from the first H1 in the content
    skill_name=$(echo "$content" | grep -m1 '^# ' | sed 's/^# //')
    : "${skill_name:=Skill Content}"
    cat <<MSGEOF
<div class="message message-skill">
  <details class="skill-content">
    <summary>Skill loaded: ${skill_name}</summary>
    <div class="skill-body">${content_html}</div>
  </details>
</div>
MSGEOF
  elif [[ "$role" == "user" ]]; then
    cat <<MSGEOF
<div class="message message-user">
  <div class="avatar">U</div>
  <div class="message-content">
    ${content_html}
  </div>
</div>
MSGEOF
  else
    cat <<MSGEOF
<div class="message message-assistant">
MSGEOF
    if [[ -n "$content_html" ]]; then
      cat <<MSGEOF
  <div class="assistant-text">${content_html}</div>
MSGEOF
    fi
    if [[ "$tool_count" -gt 0 ]]; then
      cat <<MSGEOF
  <details class="tool-calls">
    <summary>Tool calls (${tool_count})</summary>
    ${tools_html}
  </details>
MSGEOF
    fi
    cat <<MSGEOF
</div>
MSGEOF
  fi
done)

# Extract metadata for the header
META_SESSION_ID=$(echo "$JSON" | jq -r '.meta.session_id')
META_VERSION=$(echo "$JSON" | jq -r '.meta.version')
META_CWD=$(echo "$JSON" | jq -r '.meta.cwd')
META_BRANCH=$(echo "$JSON" | jq -r '.meta.branch')
META_STARTED=$(echo "$JSON" | jq -r '.meta.started')
META_ENDED=$(echo "$JSON" | jq -r '.meta.ended')
META_USER_COUNT=$(echo "$JSON" | jq -r '.meta.user_count')
META_ASSISTANT_COUNT=$(echo "$JSON" | jq -r '.meta.assistant_count')
META_MODELS=$(echo "$JSON" | jq -r '.meta.models')
TOOLS_HTML=$(echo "$JSON" | jq -r '[.tools[] | "\(.name) (\(.count))"] | join(" · ")')

# Assemble the full HTML document
cat <<'HTMLEOF' > "$OUTPUT"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Session Export</title>
<style>
:root {
  color-scheme: dark light;
  --bg: #0c0c0c;
  --fg: #d4d4d4;
  --fg-muted: #737373;
  --border: #262626;
  --surface: #171717;
  --code-bg: #1a1a1a;
  --user-border: #363636;
  --radius: 8px;
  --font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  --mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
@media (prefers-color-scheme: light) {
  :root {
    --bg: #fff;
    --fg: #1a1a1a;
    --fg-muted: #737373;
    --border: #e5e5e5;
    --surface: #f7f7f7;
    --code-bg: #f3f3f3;
    --user-border: #d4d4d4;
  }
}
*, *::before, *::after { box-sizing: border-box; }
body {
  margin: 0;
  padding: 0;
  background: var(--bg);
  color: var(--fg);
  font-family: var(--font);
  font-size: 15px;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}

/* --- Layout --- */
.page {
  display: grid;
  grid-template-columns: 260px 1fr;
  min-height: 100vh;
}
@media (max-width: 860px) {
  .page { grid-template-columns: 1fr; }
  .sidebar {
    position: static !important;
    height: auto !important;
    border-right: none !important;
    border-bottom: 1px solid var(--border);
  }
}
.sidebar {
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  border-right: 1px solid var(--border);
  padding: 1.5rem 1.25rem;
  font-size: 0.8rem;
  color: var(--fg-muted);
}
.conversation { max-width: 720px; padding: 2rem 1.5rem; }

/* --- Sidebar metadata --- */
.session-meta { margin: 0; padding: 0; }
.session-meta dt { font-weight: 600; margin-top: 0.6rem; }
.session-meta dt:first-child { margin-top: 0; }
.session-meta dd { margin: 0; word-break: break-all; }
.session-tools { margin-top: 0.75rem; }
.session-summary {
  margin-top: 1.25rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--border);
}
.session-summary h2 { margin: 0 0 0.5rem; font-size: 0.85rem; font-weight: 600; color: var(--fg); }

/* --- Messages --- */
.message { margin: 1.25rem 0; }
.message-user {
  display: grid;
  grid-template-columns: 28px 1fr;
  gap: 0.5rem;
  align-items: start;
}
.avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--border);
  color: var(--fg-muted);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.7rem;
  font-weight: 600;
  flex-shrink: 0;
}
.message-content {
  border: 1px solid var(--user-border);
  border-radius: var(--radius);
  padding: 0.5rem 0.75rem;
  min-width: 0;
}
.message-content p:first-child { margin-top: 0; }
.message-content p:last-child { margin-bottom: 0; }
.message-assistant { padding-left: 36px; }
.assistant-text p:first-child { margin-top: 0; }
.assistant-text p:last-child { margin-bottom: 0; }

/* --- Tool calls --- */
.tool-calls {
  margin: 0.75rem 0;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  font-size: 0.85rem;
}
.tool-calls summary {
  cursor: pointer;
  padding: 0.375rem 0.75rem;
  color: var(--fg-muted);
  user-select: none;
}
.tool-calls summary:hover { color: var(--fg); }
.tool-calls[open] summary { border-bottom: 1px solid var(--border); }
.tool-call {
  padding: 0.25rem 0.75rem;
  border-bottom: 1px solid var(--border);
}
.tool-call:last-child { border-bottom: none; }
.tool-name {
  font-weight: 600;
  font-size: 0.8rem;
}
.tool-call code {
  font-family: var(--mono);
  font-size: 0.8rem;
  color: var(--fg-muted);
}

/* --- Skill content (collapsed) --- */
.message-skill { padding-left: 36px; }
.skill-content {
  border: 1px solid var(--border);
  border-radius: var(--radius);
  font-size: 0.85rem;
}
.skill-content summary {
  cursor: pointer;
  padding: 0.375rem 0.75rem;
  color: var(--fg-muted);
  font-style: italic;
  user-select: none;
}
.skill-content summary:hover { color: var(--fg); }
.skill-content[open] summary { border-bottom: 1px solid var(--border); }
.skill-body {
  padding: 0.5rem 0.75rem;
  max-height: 300px;
  overflow-y: auto;
  color: var(--fg-muted);
}

/* --- Markdown content --- */
pre {
  background: var(--code-bg);
  border-radius: 6px;
  padding: 0.75rem 1rem;
  overflow-x: auto;
  font-size: 0.85rem;
  line-height: 1.5;
}
code {
  font-family: var(--mono);
  font-size: 0.9em;
}
p code {
  background: var(--code-bg);
  padding: 0.15em 0.35em;
  border-radius: 4px;
}
pre code { background: none; padding: 0; font-size: inherit; }
a { color: #60a5fa; text-decoration: underline; text-underline-offset: 2px; }
a:hover { text-decoration: none; }
@media (prefers-color-scheme: light) {
  a { color: #2563eb; }
}
ul, ol { padding-left: 1.5rem; margin: 0.5em 0; }
li { margin: 0.25em 0; }
table { border-collapse: collapse; width: 100%; margin: 0.75em 0; font-size: 0.9em; }
th, td { border: 1px solid var(--border); padding: 0.375rem 0.5rem; text-align: left; }
th { background: var(--surface); font-weight: 600; }
blockquote {
  border-left: 3px solid var(--border);
  margin: 0.75em 0;
  padding: 0.25em 1em;
  color: var(--fg-muted);
}
h1, h2, h3, h4, h5, h6 { line-height: 1.3; }
h1 { font-size: 1.5rem; }
h2 { font-size: 1.25rem; }
h3 { font-size: 1.1rem; }
strong { font-weight: 600; }
</style>
</head>
<body>
<div class="page">
HTMLEOF

# Write sidebar
cat <<HEADEREOF >> "$OUTPUT"
<aside class="sidebar">
  <dl class="session-meta">
    <dt>Session</dt><dd><code>${META_SESSION_ID}</code></dd>
    <dt>Claude Code</dt><dd>v${META_VERSION}</dd>
    <dt>Directory</dt><dd><code>${META_CWD}</code></dd>
    <dt>Branch</dt><dd>${META_BRANCH}</dd>
    <dt>Started</dt><dd>${META_STARTED}</dd>
    <dt>Ended</dt><dd>${META_ENDED}</dd>
    <dt>Messages</dt><dd>${META_USER_COUNT} user · ${META_ASSISTANT_COUNT} assistant</dd>
    <dt>Models</dt><dd>${META_MODELS}</dd>
  </dl>
  <div class="session-tools">Tools: ${TOOLS_HTML}</div>
  <div class="session-summary">
    <h2>Summary</h2>
    <!-- Replace this with a summary of the session -->
  </div>
</aside>
<main class="conversation">
HEADEREOF

# Write messages
echo "$MESSAGES_HTML" >> "$OUTPUT"

# Close HTML
cat <<'HTMLEOF' >> "$OUTPUT"
</main>
</div>
</body>
</html>
HTMLEOF

if [[ "$OUTPUT" != "/dev/stdout" ]]; then
  echo "Exported to $OUTPUT" >&2
fi
