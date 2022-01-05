resource "local_file" "kubeconfig" {
  depends_on      = [linode_lke_cluster.lotus_land_story]
  filename        = ".kube/config"
  file_permission = "0700"
  content         = base64decode(linode_lke_cluster.lotus_land_story.kubeconfig)
}
