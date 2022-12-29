# mylab local labs expirementation

## Setup

You will need to ask for the restore-secrets folder containing all the secrets to deploy the local cluster.

```bash
restore-secrets
├── argocd
│   ├── argocd-github-creds.yaml
│   └── argocd-secret.yaml
└── observability
    └── secret.yaml
```

## Getting Started

Create local cluster with [k3s](https://k3s.io/):

```console
cd overlay/local/_scripts
./start.sh
```

It will start:

- ArgoCD dashboard at [http://argo-local.mylab.com.br](https://http://argo-local.mylab.com.br/) admin: 'HnGu-igJZeoIPUv8'
- Grafana dashboard [http://observability-local.mylab.com.br](https://http://observability-local.mylab.com.br/) admin: 'password'
- Keycloak [http://identity-local.mylab.com.br](https://http://identity-local.mylab.com.br/) admin: 'password'

## ArgoCD Folders organization

### Base

**base/applications**: Contains all the applications the environments inherit from.

**base/argo/applications**: Contains the argo childs applications the parents application are pointing to.

**base/infra**: Contains k8s infra applications

### Overlay

Environments folders that inherit from base folder. It uses [kustomize](https://github.com/kubernetes-sigs/kustomize) to allow environment based customization.
