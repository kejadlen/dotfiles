terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
    }
  }
}

provider "linode" {}

# For creating a NixOS image on Linode:
#
# https://www.linode.com/docs/guides/install-nixos-on-linode/
#
resource "linode_instance" "nixos" {
  label = "nixos"
  type = "g6-nanode-1"
  region = "us-west"

  disk {
    label = "Installer"
    size = 1024
  }

  disk {
    label = "Swap"
    size = 512
    filesystem = "swap"
  }

  disk {
    label = "NixOS"
    size = 24064
  }

  config {
    label = "Installer"
    helpers {
      updatedb_disabled = false
      distro = false
      modules_dep = false
      network = false
    }
    devices {
      sda {
        disk_label = "NixOS"
      }
      sdb {
        disk_label = "Swap"
      }
      sdc {
        disk_label = "Installer"
      }
    }
    kernel = "linode/direct-disk"
    root_device = "/dev/sdc"
  }

  config {
    label = "Boot"
    helpers {
      updatedb_disabled = false
      distro = false
      modules_dep = false
      network = false
    }
    devices {
      sda {
        disk_label = "NixOS"
      }
      sdb {
        disk_label = "Swap"
      }
    }
    kernel = "linode/grub2"
  }
}
