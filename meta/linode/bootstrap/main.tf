terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
    }
  }
}

provider "linode" {
}

resource "linode_lke_cluster" "lotus_land_story" {
  label       = "lotus-land-story"
  k8s_version = "1.22"
  region      = "us-west"

  pool {
    type  = "g6-standard-1"
    count = 1
  }
}

output "kubeconfig" {
   value     = linode_lke_cluster.lotus_land_story.kubeconfig
   sensitive = true
}

