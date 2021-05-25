terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.16.0"
    }
  }
}

provider "linode" {
  # token = "$LINODE_TOKEN"
}

resource "linode_lke_cluster" "lke_cluster" {
  label       = "ramble-hard"
  k8s_version = "1.20"
  region      = "us-west"

  pool {
    type  = "g6-standard-1"
    count = 1
  }
}

