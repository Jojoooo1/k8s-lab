#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

[[ ! -x "$(command -v kubectl)" ]] && echo "kubectl not found, you need to install kubectl" && exit 1
[[ ! -x "$(command -v kustomize)" ]] && echo "kustomize not found, you need to install kustomize" && exit 1
[[ ! -x "$(command -v argocd)" ]] && echo "argocd not found, you need to install argocd-cli" && exit 1

# deploy k3s
[[ -f /usr/local/bin/k3s-killall.sh ]] && /usr/local/bin/k3s-killall.sh
[[ -f /usr/local/bin/k3s-uninstall.sh ]] && /usr/local/bin/k3s-uninstall.sh

export K3S_CONFIG_FILE="$DIR/install/k3s/k3s-config.yaml"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.22.5+k3s2" K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC='server --disable=traefik --etcd-expose-metrics=true' sh -
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config && sudo chown $USER: ~/.kube/k3s-config

export KUBECONFIG=~/.kube/k3s-config

sleep 5

message ">>> deploying kubernetes applications"

# Directory containing secret located outside of projets
SECRET_DIR="../../../../restore-secrets"

# Deploy secret used by loki to read from existing logs source
kubectl create namespace observability
SECRET_OBSERVABILITY_DIR=$SECRET_DIR/observability
kubectl apply -f $SECRET_OBSERVABILITY_DIR/secret.yaml

# Deploy argocd
kubectl create namespace argocd
ARGO_DIR=./install/argo
kustomize build $ARGO_DIR --load-restrictor LoadRestrictionsNone | kubectl apply -f -
kubectl -n argocd rollout status deployment/argocd-server
kubectl apply -f $ARGO_DIR/parent.yaml

message ">>> Awaiting parent-applications to sync..."
until argocd login --core --username admin --password HnGu-igJZeoIPUv8 --insecure; do :; done
kubectl config set-context --current --namespace=argocd
until argocd app sync parent-applications; do echo "awaiting parent-applications to be sync..." && sleep 10; done

message ">>> Applications"
echo ">>> argo: http://argo-local.mylab.com.br - username: 'admin', password: 'HnGu-igJZeoIPUv8'"
echo ">>> observability: http://observability-local.mylab.com.br - username: 'admin', password: 'password'"
echo ">>> keycloak: http://identity-local.mylab.com.br - username: 'admin', password: 'password'"
# message ">>> Note: you can restore keycloak dump using script restore-keycloak-db.sh"

message ">>> Deploying nginx-ingress"
until argocd app sync ingress-nginx; do echo "awaiting ingress-nginx to be deployed..." && sleep 20; done

NGINX_INGRESS_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -ojson | jq -r '.status.loadBalancer.ingress[].ip')
echo "NGINX_INGRESS_IP=$NGINX_INGRESS_IP"

message ">>> deploying argo-ingress"
kubectl apply -f $ARGO_DIR/config/argo-ing.yaml

# Add hosts
message ">>> adding hosts to /etc/hosts"
./install/utilities/add-hosts.sh
