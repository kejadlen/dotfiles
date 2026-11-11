#!/usr/bin/env bash

set -euo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Matches `sops` as a whole word anywhere, so chained, piped, and path-qualified
# invocations are caught along with leading ones.
sops_word='(^|[^[:alnum:]_.-])sops($|[^[:alnum:]_.-])'

main() {
    local command
    command=$(jq --raw-output '.tool_input.command // ""')

    if [[ "$command" =~ $sops_word ]]; then
        echo "Don't run sops — it decrypts secrets. Ask the user to run it instead." >&2
        exit 2
    fi
}

main "$@"
