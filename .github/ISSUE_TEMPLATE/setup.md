- [ ] Install Homebrew
  `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

- [ ] Install [Xcode]

[xcode]: https://developer.apple.com/download/more/

- [ ] Install Ansible
  `brew install ansible`

- [ ] Install `mas
  `brew install mas`
  - [ ] Sign in to the Mac App Store

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

- [ ] macOS preferences
  - [ ] General
    - [ ] Appearance -> Auto
  - [ ] Displays
    - [ ] Night Shift
  - [ ] Keyboard
    - [ ] Modifiers
    - [ ] Function keys

- [ ] Setup programs
  - [ ] 1Password
    - [ ] Change hotkeys
  - [ ] Alfred
  - [ ] Arq
  - [ ] Bartender
  - [ ] Dash
  - [ ] Encrypt.me
  - [ ] Fantastical
  - [ ] Firefox
  - [ ] MailMate
  - [ ] Slack
  - [ ] hammerspoon
  - [ ] syncthing
