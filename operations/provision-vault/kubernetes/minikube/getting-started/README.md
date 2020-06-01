# Vault with Kubernetes

These assets are provided to perform the steps described in the [Vault Installation to Minikube via Helm](https://learn.hashicorp.com/vault/getting-started-k8s/minikube) guide.

---

**NOTE:** For the purpose of demonstration, this guide runs Minikube as a
Kubernetes environment. If you already have a running Kubernetes environment
in a cloud, you can use that instead.

## Prerequisites

To perform the tasks described in this guide, you need:

This guide requires the [Kubernetes command-line interface
(CLI)](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and the [Helm
CLI](https://helm.sh/docs/helm/) installed,
[Minikube](https://minikube.sigs.k8s.io), the Vault and Consul Helm charts, the
sample web application, and additional configuration to bring it all together.

## Demo Steps

Start Minikube.

```
$ minikube start
```

Next, start the Kubernetes dashboard.

```
$ minikube dashboard
```

Install the Consul Helm chart version 0.18.0 with pods prefixed with the name
`consul` and apply the values found in `helm-consul-values.yml`.

```shell
$ helm install consul \
    --values helm-consul-values.yml \
    https://github.com/hashicorp/consul-helm/archive/v0.18.0.tar.gz
```

Install the Vault Helm chart version 0.4.0 with pods prefixed with the name
`vault` and apply the values found in `helm-vault-values.yml`.

```shell
$ helm install vault \
    --values helm-vault-values.yml \
    https://github.com/hashicorp/vault-helm/archive/v0.4.0.tar.gz
```

Initialize Vault with one key share and one key threshold.

```shell
$ kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
```

View the unseal key found in `cluster-keys.json`.

```shell
$ cat cluster-keys.json | jq -r ".unseal_keys_b64[]"
rrUtT32GztRy/pVWmcH0ZQLCCXon/TxCgi40FL1Zzus
```

Create a variable named VAULT_UNSEAL_KEY to capture the Vault unseal key.

```shell
$ VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
```

Unseal Vault running on the `vault-0` pod.

```shell
$ kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.3.2
Cluster Name           vault-cluster-40bde7f6
Cluster ID             7e0355e2-ee66-4d9e-f4eb-42ef453b857d
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>
```

Unseal Vault running on the `vault-1` pod.

```shell
$ kubectl exec vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
# ...
```

Unseal Vault running on the `vault-2` pod.

```shell
$ kubectl exec vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
# ...
```

View the root token found in `cluster-keys.json`.

```shell
$ cat cluster-keys.json | jq -r ".root_token"
s.VgQvaXl8xGFO1RUxAPbPbsfN
```

First, start an interactive shell session on the `vault-0` pod.

```shell
$ kubectl exec -it vault-0 -- /bin/sh
/ $
```

Login with the root token.

```shell
/ $ vault login s.VgQvaXl8xGFO1RUxAPbPbsfN
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.g3dGqNy5IYrj8E4EU8mSPeL2
token_accessor       JVsMJHVu6rTWbPLlYmWQTq1R
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

Enable kv-v2 secrets at the path `secret`.

```shell
/ $ vault secrets enable -path=secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/
```

Create a secret at path `secret/webapp/config` with a `username` and `password`.

```shell
/ $ vault kv put secret/webapp/config username="static-user" password="static-password"
Key              Value
---              -----
created_time     2020-03-24T19:13:06.72377543Z
deletion_time    n/a
destroyed        false
version          1
```

Verify that the secret is defined at the path `secret/webapp/config`.

```shell
/ $ vault kv get secret/webapp/config
====== Metadata ======
Key              Value
---              -----
created_time     2020-03-24T19:13:06.72377543Z
deletion_time    n/a
destroyed        false
version          1

====== Data ======
Key         Value
---         -----
password    static-password
username    static-user
```

Enable the Kubernetes authentication method.

```shell
/ $ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
```

Configure the Kubernetes authentication method to use the service account
token, the location of the Kubernetes host, and its certificate.

```shell
/ $ vault write auth/kubernetes/config \
        token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
        kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
Success! Data written to: auth/kubernetes/config
```

Write out the policy named `webapp` that enables the `read` capability for
secrets at path `secret/data/webapp/config`


```shell
/ $ vault policy write webapp - <<EOF
path "secret/data/webapp/config" {
  capabilities = ["read"]
}
EOF
Success! Uploaded policy: webapp
```

Create a Kubernetes authentication role, named `webapp`, that connects the
Kubernetes service account name and `webapp` policy.

```shell
$ vault write auth/kubernetes/role/webapp \
        bound_service_account_names=vault \
        bound_service_account_namespaces=default \
        policies=webapp \
        ttl=24h
Success! Data written to: auth/kubernetes/role/webapp
```

Lastly, exit the the `vault-0` pod.

```shell
/ $ exit
$
```

Deploy the webapp in Kubernetes by applying the file `deployment-01-webapp.yml`.

```shell
$ kubectl apply --filename deployment-01-webapp.yml
deployment.apps/webapp created
```

Get all the pods within the `default` namespace.

```shell
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
consul-consul-6jcfj                     1/1     Running   0          19m
consul-consul-server-0                  1/1     Running   0          19m
vault-0                                 1/1     Running   0          14m
vault-1                                 1/1     Running   0          14m
vault-2                                 1/1     Running   0          14m
vault-agent-injector-5945fb98b5-thczv   1/1     Running   0          14m
webapp-5c76d96c6-r4mcq                  1/1     Running   0          2m43s
```

Finally, perform a `curl` request at `http://localhost:8080`.

```shell
$ kubectl exec webapp-5c76d96c6-r4mcq -- curl -s http://localhost:8080
{"password"=>"static-secret", "username"=>"static-user"}%
```
