#!/bin/bash -x
# jboero@hashicorp.com - 9-APR-2019
# A Q&D script to stand up K8s cluster + helm + consul + vault locally on single-node K8s
# Prereqs - Requires kubectl, helm, kubeadm to be installed.
# To use the Cockpit visualization, must install cockpit-kubernetes and google-chrome-stable or browser of your choice.
# WARNING - this will overwrite your ~/.kube/config, so make sure to backup if necessary.

sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Mkdir local for 3 persistent volumes if necessary.
sudo mkdir -p /aux/kubernetes/s{0,1,2}

# WARNING - 
cp ~/.kube/config ~/.kube/config.old
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $USER $HOME/.kube/config

# Pop open cockpit locally if it's installed.
# Change this to actual browser command if necessary.
xdg-open http://localhost:9090/kubernetes#/topology &

# Taint master so we can schedule pods locally.
kubectl taint nodes --all node-role.kubernetes.io/master-

# Install Calico
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# If internal cockpit.
#kubectl create -f https://raw.githubusercontent.com/cockpit-project/cockpit/master/containers/kubernetes-cockpit.json

# Create Helm service account and 3 local persistent volumes (dirs).
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
---
apiVersion: v1
kind: List
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: local0
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 10Gi
    hostPath:
      path: /aux/kubernetes/s0
      type: ""
    persistentVolumeReclaimPolicy: Recycle
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: local1
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 10Gi
    hostPath:
      path: /aux/kubernetes/s1
      type: ""
    persistentVolumeReclaimPolicy: Recycle
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: local2
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 10Gi
    hostPath:
      path: /aux/kubernetes/s2
      type: ""
    persistentVolumeReclaimPolicy: Recycle
    volumeMode: Filesystem
metadata:
  resourceVersion: ""
  selfLink: ""

EOF

# Init helm
helm init --service-account helm
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator

# Install official consul chart directly.  (No Hashicorp helm repo yet)

until helm install --name myconsul https://github.com/hashicorp/consul-helm/archive/v0.7.0.tar.gz --set server.affinity=""
do
  echo "Helm waiting for tiller"
  sleep 5
done

helm install incubator/vault --name "v0" --set vault.dev=false --set vault.config.storage.consul.address="myconsul-server:8500",vault.config.storage.consul.path="vault",vault.config.ui="true"
kubectl expose deployment "v0-vault" --target-port=8200 --type=NodePort --name="vault0-internal"

kubectl get all --all-namespaces
kubectl describe svc/vault0-internal
