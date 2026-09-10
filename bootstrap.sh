#!/usr/bin/env bash

set -euo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

dotfiles="$(cd "$(dirname "$0")" && pwd)"

main() {
  if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl --fail --silent --show-error --location https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # A fresh Homebrew install isn't on PATH until the shell config is linked.
  eval "$(/opt/homebrew/bin/brew shellenv)"

  if ! command -v dotslash &> /dev/null; then
    brew install dotslash
  fi

  # frork shells out to DotSlash tools like bat, which live in bin/.
  export PATH="$dotfiles/bin:$PATH"

  "$dotfiles/bin/frork" satisfy "$dotfiles/frork/main.fnl"
}

main "$@"
