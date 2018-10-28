- [ ] Install Homebrew
  `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

- [ ] Install Ansible and mas
  `brew install ansible mas`

- [ ] Xcode
  - [ ] Install Xcode
    `mas install 497799835`

  - [ ] Open Xcode to install additional components
    `open Xcode`

  - [ ] Accept the Xcode license
    `sudo xcodebuild -license`

  - [ ] Install the command line developer tools from Xcode
    `xcode-select --reset`

- [ ] Enable Remote Login
  `open /System/Library/PreferencePanes/SharingPref.prefPane`

- [ ] Clone dotfiles
  `git clone --recursive https://github.com/kejadlen/dotfiles.git ~/.dotfiles`

- [ ] Run Ansible
  ```shell
  cd ~/.dotfiles/ansible
  echo "localhost ansible_connection=local" > hosts.private
  ansible-playbook main.yml --ask-pass --ask-become-pass
  ```

- [ ] Set Keyboard preferences
  - [ ] Modifiers
  - [ ] Function keys

- [ ] Setup programs
  - [ ] 1Password
  - [ ] Firefox
  - [ ] Arq
