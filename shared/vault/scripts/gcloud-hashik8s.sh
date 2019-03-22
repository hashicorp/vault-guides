#!/bin/bash -x
# John Boero - jboero@hashicorp.com
# A Q&D script to stand up K8s cluster + helm + consul + vault on GKE
# Prereqs - Requires gcloud, kubectl, helm to be installed.

gcloud container clusters create --machine-type=g1-small --preemptible --num-nodes=1 --region=europe-west2 hashik8s
gcloud container clusters get-credentials hashik8s --region=europe-west2

kubectl create -f -<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: helm
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: helm
    namespace: kube-system
EOF

# Optionally enable Cockpit to watch services incoming.
#kubectl create -f https://raw.githubusercontent.com/cockpit-project/cockpit/master/containers/kubernetes-cockpit.json

# For now use incubator chart.  Will substitute with supported chart when available.
helm init --service-account helm
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator

# Watch until output changes to "running" for kube to be ready.
watch -n 5 -g kubectl get all --all-namespaces

# Install official consul chart directly.  (No Hashicorp helm repo yet)
helm install --name myconsul https://github.com/hashicorp/consul-helm/archive/v0.6.0.tar.gz

# Install community vault chart via repo.
helm install incubator/vault --name helm-vault --set vault.dev=false --set vault.config.storage.consul.address="myconsul-server:8500",vault.config.storage.consul.path="vault"

# Expose another service for public LoadBalancer
kubectl expose deployment helm-vault --target-port=8200 --type=LoadBalancer --name=vault-internal

# We'd need to wait for the LB to get a public IP and unseal all pods.
kubectl get all --all-namespaces
