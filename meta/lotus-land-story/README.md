# Lotus Land Story

- `LINODE_TOKEN`: See https://cloud.linode.com/profile/tokens
- `KUBECONFIG`: Set to `.kube/config`

```
# Install tooling
brew install helm kubernetes-cli terraform

# Bootstrapping
(cd bootstrap && terraform init && terraform apply)

# Terraform commands
terraform plan
terraform apply
terraform destroy
```

## References

- https://learnk8s.io/terraform-lke
- https://cert-manager.io/docs/tutorials/acme/ingress/

## TODO

- Encrypt data at rest?
  - https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

