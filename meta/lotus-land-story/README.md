# Lotus Land Story

- `LINODE_TOKEN`: See https://cloud.linode.com/profile/tokens
- `KUBECONFIG`: Set to `.kube/config`

```
# Install tooling
brew install kubernetes-cli terraform

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
- https://www.linode.com/community/questions/20215/how-to-re-attach-persistent-volume-to-pod-when-claim-is-deleted
- Terraform providers
  - [kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
  - [linode](https://registry.terraform.io/providers/linode/linode/latest/docs)

  > At first I get new PVC uid by command:
  > `kubectl get pvc my-pvc-0 -o yaml | grep uid`
  > Then I edit new empty volume, what provisioned by CSI Driver and remove claim - pv binding by removing claimRef section in:
  > `kubectl edit pv pvc-yyyyyyyyyyyy`
  > After that new PV change status to "Available" and can be deleted.
  > Then I edit old PV, what I want to bind with pod via new claim and put PVC uid to claimRef section:
  > `kubectl edit pv pvc-xxxxxxxxxxx`
  > After that, the old volume became associated with the new claim.

## TODO

- Encrypt data at rest?
  - https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

