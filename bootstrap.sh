#!/usr/bin/env zsh

set -euo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

cd "$(dirname "$0")"

main() {
  if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is required but not installed."
    echo "Please install Homebrew first: https://brew.sh/"
    exit 1
  else
    echo "Homebrew is installed."
  fi

  if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible via Homebrew..."
    brew install ansible
  else
    echo "Ansible is already installed."
  fi

  mkdir -p boxen

  if [ ! -d "$HOME/src/boxen" ]; then
    echo "Cloning boxen repository..."
    mkdir -p "$HOME/src"
    git clone https://git.kejadlen.dev/alpha/boxen.git "$HOME/src/boxen"
  else
    echo "Boxen repository already exists."
  fi

  cd ~/src/boxen
  ansible-playbook -l localhost local/main.yml
}

main "$@"
