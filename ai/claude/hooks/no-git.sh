#!/usr/bin/env bash
# Block bare `git` commands — use jj instead.
# Allows commands that happen to contain "git" (e.g., gh, gitea, git.kejadlen.dev).

command=$(jq -r '.tool_input.command // ""')

# Strip leading whitespace and env assignments, then check for `git` as the first word.
bare_command=$(echo "$command" | sed 's/^[[:space:]]*//' | sed 's/^[A-Za-z_][A-Za-z_0-9]*=[^ ]* *//')

if [[ "$bare_command" =~ ^git($|[[:space:]]) ]]; then
  echo "Use jj, not git. See the jj skill for command reference." >&2
  exit 2
fi
