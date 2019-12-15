# On Fire Within

## Setup

- [Installing Hass.io](https://www.home-assistant.io/hassio/installation/)

1. `ansible-playbook playbooks/pi/bootstrap.yml`
1. `ansible-playbook on-fire-within/bootstrap.yml`
1. `curl -fsSL get.docker.com | sh`
  - `sudo usermod -aG docker alpha`
1. `curl -sL "https://raw.githubusercontent.com/home-assistant/hassio-installer/master/hassio_install.sh" | bash -s -- -m raspberrypi4`
1. `ansible-playbook on-fire-within/main.yml`

## Notes

- `/usr/share/hassio`
