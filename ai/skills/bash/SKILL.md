---
name: bash
description: Use when writing, reviewing, or debugging shell scripts — covers safe defaults, shellcheck, executable permissions, and scripting patterns
---

# Bash scripting

## New scripts

Start with safe defaults:

```bash
#!/usr/bin/env bash

set -euo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

main() {
}

main "$@"
```

`set -euo pipefail` exits on errors, undefined variables, and pipe
failures. The `TRACE` guard provides opt-in tracing via `TRACE=1
./script.sh` without cluttering normal output.

Wrapping logic in `main()` and calling `main "$@"` at the bottom
prevents partial execution if the script is truncated during
download or write.

## Executable permissions

Scripts meant to be run directly need the executable bit (`chmod +x`).
Check permissions before committing — a missing executable bit is a
common oversight that breaks scripts silently when deployed.

Non-executable shell files are appropriate for files meant to be
sourced (`. script.sh` or `source script.sh`), not run directly.

## Shellcheck

Run [shellcheck](https://www.shellcheck.net/) on all shell scripts
before committing.

```bash
shellcheck path/to/script.sh
```

Fix all warnings. If a warning is genuinely inapplicable, disable it
inline with a directive comment on the line above:

```bash
# shellcheck disable=SC2059
printf "$fmt" "$arg"
```

Don't disable warnings globally or at the file level unless there's a
compelling reason.

---

*This is a self-improving skill — see the `self-improving-skills` skill.*
