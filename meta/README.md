# ansible

## Usage

```sh
# Install Homebrew
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

# Load Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install Ansible
brew install ansible

# Clone dotfiles
git clone --recursive https://github.com/kejadlen/dotfiles.git ~/.dotfiles

# Run Ansible
cd ~/.dotfiles/meta
echo "localhost ansible_connection=local" > hosts.private
ansible-playbook main.yml --ask-become-pass
```

- [x] Change computer name under System Preferences -> Sharing

- [x] 1Password: the first app to set up, since it has the keys for everything else
  - [x] Don't show Archive vaults
- [x] [syncthing](http://localhost:8384): start syncing `~/sync`
  - [x] `ln -s ~/sync/dotfiles ~/.dotfiles`
- [x] Alfred
  - [x] Hotkey
  - [x] Clipboard
  - [x] Appearance
- [x] Hammerspoon
- [x] Firefox
  - [x] Dark Reader

### macOS System Preferences

- [ ] Desktop & Screen Saver
- [x] Siri
  - [x] Disable `Show Siri in menu bar`
- [x] Notifications & Focus
  - [x] Messages - disable sound
- [x] Sound
  - [x] Disable startup sound
  - [x] Disable user interface sound effects
- [x] Touch ID
  - [x] Rename to "right index"
  - [x] Add left index
- [x] Keyboard
  - [x] Modifier keys
- [x] Displays
  - [x] Scaled
  - [x] Night Shift
- [x] Sharing
  - [x] Remote Login

### Other Applications

In rough order of importance:

- [ ] Arq (for MailMate)
- [x] [MailMate](https://manual.mailmate-app.com/rebuild)
  - [x] `~/Library/Application Support/MailMate/*.plist`
  - [x] `~/Library/Application Support/MailMate/Resources/` (doesn't seem to exist?)
  - [x] `~/Library/Application Support/MailMate/Bundles/` (doesn't seem to exist?)
  - [x] `~/Library/Preferences/com.freron.MailMate.plist`
- [x] Fantastical
- [x] Contacts (Monica)
- [x] Bartender
- [ ] Dash
- [x] Reeder
- [x] Shareful
- [ ] Things
- [ ] Anki
- [ ] Social
  - [x] Twitterrific
  - [x] Slack
  - [x] Discord
  - [ ] Telegram
  - [ ] Signal

### Etc

- [x] Install Xcode (`mas install 497799835`)

## Development

Ansible tags are indispensable when tweaking the config:

```
- command: echo debug
  tags: debug
```

``` shell
ansible-playbook main.yml --ask-become-pass --tags=debug
```

## Raspberry Pi

This should be moved elsewhere...

1. [Download Raspberian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/)
1. Install Etcher: `brew cask install balenaetcher`
1. [Flash the SD card](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)

1. [Enable SSH](https://www.raspberrypi.org/documentation/remote-access/ssh/)

1. Run the Ansible playbooks
  1. Add the host to the `pi_bootstrap` group and set the `password` variable
     on the host
  1. Connect to the host via SSH (so Ansible can piggyback off the existing
     connection and not have to deal with password shenanigans)
  1. `ansible-playbook playbooks/pi/bootstrap.yml`
  1. `ansible-playbook {{ host }}/main.yml`

### etc

1. Use `raspi-config` to set up the WiFi
  - [Additional setup](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md)
  - Add `scan_ssid=1` to `/etc/wpa_supplicant/wpa_supplicant.conf`
  - Restart WiFi: `wpa_cli -i wlan0 reconfigure`
1. Use `raspi-config` to set the keyboard layout

