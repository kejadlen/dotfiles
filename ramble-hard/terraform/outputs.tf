resource "local_file" "kubeconfig" {
  depends_on      = [linode_lke_cluster.ramble-hard]
  filename        = "kube.config.private"
  file_permission = "0600"
  content         = base64decode(linode_lke_cluster.ramble-hard.kubeconfig)
}
