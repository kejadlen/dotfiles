# Lotus Land Story

- `LINODE_TOKEN`: See https://cloud.linode.com/profile/tokens
- `KUBECONFIG`: Set to `.kube/config`

```
# Install tooling
brew install helm kubernetes-cli terraform

# One-time initialization
terraform init

# Terraform commands
terraform plan
terraform apply
terraform destroy

# cert-manager
helm repo add jetstack https://charts.jetstack.io
kubectl create namespace cert-manager
helm template \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.6.1 \
  --set installCRDs=true \
  > manifests/cert-manager.yml
kubectl apply -f manifests/cert-manager.yml

cat manifests/letsencrypt-staging.yml | envsubst | kubectl apply -f -
cat manifests/letsencrypt-prod.yml | envsubst | kubectl apply -f -

# nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm template quickstart ingress-nginx/ingress-nginx > manifests/ingress-nginx.yml
kubectl apply -f manifests/ingress-nginx.yml

# kuard
cat manifests/kuard.yml | envsubst | kubectl apply -f -
```

## References

- https://learnk8s.io/terraform-lke
- https://cert-manager.io/docs/tutorials/acme/ingress/

## TODO

- Encrypt data at rest?
  - https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

