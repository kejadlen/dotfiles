# ansible

## Raspberry Pi

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

