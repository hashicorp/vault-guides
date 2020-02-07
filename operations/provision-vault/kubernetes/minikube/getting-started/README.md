# Vault with Kubernetes

These assets are provided to perform the steps described in the [Vault Installation to Minikube via Helm](https://learn.hashicorp.com/vault/getting-started-k8s/minikube) guide.

---

**NOTE:** For the purpose of demonstration, this guide runs Minikube as a
Kubernetes environment. If you already have a running Kubernetes environment
in a cloud, you can use that instead.

## Prerequisites

To perform the tasks described in this guide, you need:

- [Minikube installed](https://kubernetes.io/docs/tasks/tools/install-minikube/)

## Demo Steps

Start Minikube.

```
$ minikube start --memory 4096
```

Next, start the Kubernetes dashboard.

```
$ minikube dashboard
```

The Vault Helm chart only supports Helm version 2.x. Initialize Helm and start
Tiller.

```shell
$ helm init
```

Wait for the Tiller pod to finish its startup.

Launch the consul helm chart with the additional values found in the directory.

```shell
$ helm install --name consul \
    --values helm-consul-values.yml \
    https://github.com/hashicorp/consul-helm/archive/v0.15.0.tar.gz
```

Launch the vault helm chart with the following options:

```shell
$ helm install --name vault \
    --values helm-vault-values.yml \
    https://github.com/hashicorp/vault-helm/archive/v0.3.0.tar.gz
```

Three services are running and each one needs to be unsealed.

Run the vault operator init command to generate the unseal key and root token

```shell
$ kubectl exec -ti vault-0 -- vault operator init -n 1 -t 1

Unseal Key 1: mxW5SAU/10DOuNYaNXFZgkb/gedX+1UoK626xXM07Lg=

Initial Root Token: s.GNJraFHHzZZj4NSOtx6Qpvfo
...
```

Unseal each of the vault services by name.

```shell
$ kubectl exec -ti vault-0 -- vault operator unseal
$ kubectl exec -ti vault-1 -- vault operator unseal
$ kubectl exec -ti vault-2 -- vault operator unseal
```

Enable communication with a Vault server.

```
# Port-forward to be able to talk to one of the vault services
$ kubectl port-forward vault-0 8200:8200

# set the vault address to localhost:8200
$ export VAULT_ADDR="http://localhost:8200"

# set the token to the initial token
$ export VAULT_TOKEN=s.GNJraFHHzZZj4NSOtx6Qpvfo
```

Enable kv-v2 secrets at `secret`.

```shell
$ vault secrets enable -path=secret kv-v2
```

Put a username and password secret at `webapp/config`.

```shell
$ vault kv put secret/webapp/config username="choochoo" password="FOUNDIT"
```

Verify that the secret exists.

```shell
$ vault read secret/data/webapp/config -format=json
```

Next, its time to setup authentication between Vault and Kubernetes.

Set environment variables for the following values stored within Kubernetes.

```
# Set VAULT_SA_NAME to the service account you created earlier
$ export VAULT_SA_NAME=$(kubectl get sa vault -o jsonpath="{.secrets[*]['name']}")

# Set SA_JWT value to the service account JWT used to access the TokenReview API
$ export SA_JWT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
$ export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

# Set K8S_HOST to minikube IP address
$ export K8S_HOST=$(minikube ip)
```

Enable kubernetes authentication method.

```shell
$ vault auth enable kubernetes
```

Configure Vault to communicate with the Kubernetes (Minikube) cluster.

```shell
$ vault write auth/kubernetes/config \
        token_reviewer_jwt="$SA_JWT" \
        kubernetes_host="https://$K8S_HOST:8443" \
        kubernetes_ca_cert="$SA_CA_CRT"
```

A Kubernetes service account named `vault` was automatically created.

Apply configuration of permissions for this service account found in
`vault-service-account.yml`.

```
$ kubectl apply --filename vault-auth-service-account.yml
```

Write out a policy called `webapp` which reads secrets defined at the `secret/data/webapp` path.

```shell
$ vault policy write webapp - <<EOH
path "secret/data/webapp/*" {
  capabilities = ["read"]
}
EOH
```

Create a role, named `webapp`, that connects the Kubernetes service account
and the `webapp` policy.

```shell
# Create a role named, 'example' to map Kubernetes Service Account to
#  Vault policies and default token TTL
$ vault write auth/kubernetes/role/webapp \
        bound_service_account_names=vault \
        bound_service_account_namespaces=default \
        policies=webapp \
        ttl=24h
```

Start a secret consumer defined in file `k8s-webapp.yaml`.

```shell
$ kubectl apply -f k8s-webapp.yaml
```

### Verification

Get the name of the webapp pod.

```shell
$ kubectl get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
consul-consul-connect-injector-webhook-deployment-568996d6ndswv   1/1     Running   0          155m
consul-consul-dpdbz                                               1/1     Running   0          155m
consul-consul-server-0                                            1/1     Running   0          155m
webapp-simple-c54944b4c-84kwf                                     1/1     Running   0          7m45s
vault-0                                                           1/1     Running   0          155m
vault-1                                                           1/1     Running   0          155m
vault-2                                                           1/1     Running   0          155m
```

Map your localhost port 9292 to the webapp pod port 9292.

```shell
$ kubectl port-forward webapp-simple-c54944b4c-84kwf 9292:9292
```

```shell
curl http://localhost:9292
```

## Troubleshooting

1. Check the status of the pods

```shell
$ kubectl get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
consul-consul-connect-injector-webhook-deployment-568996d6ndswv   1/1     Running   0          155m
consul-consul-dpdbz                                               1/1     Running   0          155m
consul-consul-server-0                                            1/1     Running   0          155m
webapp-simple-c54944b4c-84kwf                                     1/1     Running   0          7m45s
vault-0                                                           1/1     Running   0          155m
vault-1                                                           1/1     Running   0          155m
vault-2                                                           1/1     Running   0          155m
```

1. Check the logs of the webapp pod

```shell
$ kubectl logs webapp-simple-c54944b4c-84kwf
[2019-09-26 21:27:47] INFO  WEBrick 1.4.2
[2019-09-26 21:27:47] INFO  ruby 2.6.2 (2019-03-13) [x86_64-linux]
[2019-09-26 21:27:47] INFO  WEBrick::HTTPServer#start: pid=1 port=9292
```

1. In the minikube dashboard, click **Pods** under **Workloads** to verify that
`webapp` Pod has been created successfully.


1. Login to the app and run it yourself:

```shell
$ kubectl exec -it webapp-simple-c54944b4c-lwv7t /bin/bash
```

On that system you can then run the service in the `/app` directory.

```shell
$ rackup -p 9191
```

```shell
$ apt-get install vim
```
