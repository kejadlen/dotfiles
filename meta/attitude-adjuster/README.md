# Attitude Adjuster

## Installation notes

1. [Download Raspberian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/)
1. Install Etcher: `brew cask install balenaetcher`
1. [Flash the SD card](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)

1. [Enable SSH](https://www.raspberrypi.org/documentation/remote-access/ssh/)

1. Run the Ansible playbooks
  - `ansible-playbook --extra-vars "ansible_user=pi" --ask-pass attitude-adjuster/bootstrap.yml`
  - `ansible-playbook attitude-adjuster/main.yml`

## Optional

1. Use `raspi-config` to set up the WiFi
  - [Additional setup](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md)
  - Add `scan_ssid=1` to `/etc/wpa_supplicant/wpa_supplicant.conf`
  - Restart WiFi: `wpa_cli -i wlan0 reconfigure`
1. Use `raspi-config` to set the keyboard layout

