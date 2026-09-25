#!/usr/bin/env bash
# Block commands that reference .envrc — it loads secrets (sops/direnv).
# Matches any mention, since even `wc -l .envrc` leaks information.

command=$(jq -r '.tool_input.command // ""')

if [[ "$command" == *".envrc"* ]]; then
  echo ".envrc contains secrets. Ask the user how env/secrets load instead of reading it." >&2
  exit 2
fi
