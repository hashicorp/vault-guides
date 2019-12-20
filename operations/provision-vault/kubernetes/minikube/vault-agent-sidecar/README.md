# Vault Agent Injector Example

## Prerequisites

This guide requires the [Kubernetes command-line interface
(CLI)](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and the [Helm
CLI](https://helm.sh/docs/helm/) installed,
[Minikube](https://minikube.sigs.k8s.io), and additional configuration to bring
it all together.

This guide was last tested 20 Dec 2019 on a macOS 10.15.2 using this
configuration:

```shell
$ docker version
Client: Docker Engine - Community
 Version:           19.03.5
 ...

$ minikube version
minikube version: v1.5.2
commit: 792dbf92a1de583fcee76f8791cff12e0c9440ad

$ helm version
Client: &version.Version{SemVer:"v2.16.1", GitCommit:"bbdfe5e7803a12bbdf97e94cd847859890cf4050", GitTreeState:"clean"}
# Tiller's version appears after `helm init` later in the guide.
Error: could not find tiller
```

Although we recommend these software versions, the output you see may
vary depending on your environment and the software versions you use.

First, follow the directions for [installing
Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/), including
VirtualBox or similar.

Next, install [kubectl CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
and [helm CLI](https://github.com/helm/helm#install).

On Mac with [Homebrew](https://brew.sh).

```shell
$ brew install kubernetes-cli
$ brew install helm@2
```

~> **Helm versions:** Currently, the Vault Helm chart does not support version
  3.x. If you already have helm 3.x installed, you can use version 2 instead by
  redefining your PATH `export PATH=/usr/local/opt/helm@2/bin:$PATH`.

On Windows with [Chocolatey](https://chocolatey.org/):

```shell
$ choco install kubernetes-cli
$ choco install kubernetes-helm --version 2.16.0
```

Next, retrieve the web application and additional configuration by cloning the
[hashicorp/vault-guides](https://github.com/hashicorp/vault-guides) repository
from GitHub.

```shell
$ git clone https://github.com/hashicorp/vault-guides.git
```

This repository contains supporting content for all of the Vault learn guides.
The content specific to this guide can be found within a sub-directory.

Go into the
`vault-guides/operations/provision-vault/kubernetes/minikube/vault-agent-sidecar`
directory.

```shell
$ cd vault-guides/operations/provision-vault/kubernetes/minikube/vault-agent-sidecar
```

~> **Working directory:** This guide assumes that the remainder of commands are
executed within this directory.

## Start Minikube

Start a Kubernetes cluster with 4096 Megabytes (MB) of memory:

```shell
$ minikube start --memory 4096
😄  minikube v1.5.2 on Darwin 10.15.2
✨  Automatically selected the 'hyperkit' driver (alternates: [virtualbox])
🔥  Creating hyperkit VM (CPUs=2, Memory=4096MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.16.2 on Docker '18.09.9' ...
🚜  Pulling images ...
🚀  Launching Kubernetes ...
⌛  Waiting for: apiserver
🏄  Done! kubectl is now configured to use "minikube"
```

Verify the status of the Minikube cluster:

```shell
$ minikube status
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

In **another terminal**, launch the minikube dashboard:

```shell
$ minikube dashboard
```

## Initialize Helm

Initialize [Helm](https://helm.sh/docs/helm/) and start Tiller:

```shell
$ helm init
$HELM_HOME has been configured at $HOME/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
```

Verify that Tiller is running by getting all the pods within the `kube-system`
namespace:

```shell
$ kubectl get pods --namespace kube-system
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-5c98db65d4-s8cdv                1/1     Running   1          7m17s
coredns-5c98db65d4-vh5tw                1/1     Running   1          7m17s
etcd-minikube                           1/1     Running   0          6m20s
kube-addon-manager-minikube             1/1     Running   0          6m19s
kube-apiserver-minikube                 1/1     Running   0          6m12s
kube-controller-manager-minikube        1/1     Running   0          6m9s
kube-proxy-llgmm                        1/1     Running   0          7m17s
kube-scheduler-minikube                 1/1     Running   0          6m12s
kubernetes-dashboard-7b8ddcb5d6-7gs2l   1/1     Running   0          7m16s
storage-provisioner                     1/1     Running   0          7m16s
tiller-deploy-75f6c87b87-n4db8          1/1     Running   0          21s
```


## Install the Vault Helm chart

Install the Vault Helm chart version 0.3.0 with pods prefixed with the name `vault`:

```shell
$ helm install --name vault \
    --set "server.dev.enabled=true" \
    https://github.com/hashicorp/vault-helm/archive/v0.3.0.tar.gz
NAME:   vault
LAST DEPLOYED: Fri Dec 20 11:56:33 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:

...

NOTES:

...

Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault

```

To verify, get all the pods within the `default` namespace:

```shell
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          80s
vault-agent-injector-5945fb98b5-tpglz   1/1     Running   0          80s
```

## Set a secret in Vault

Start an interactive shell session on the `vault-0` pod:

```shell
$ kubectl exec -it vault-0 /bin/sh
/ $
```

Your system prompt is replaced with a new prompt `/ $`. Commands issued at this
prompt are executed on the `vault-0` container.

Enable kv-v2 secrets at the path `internal`:

```shell
/ $ vault secrets enable -path=internal kv-v2
Success! Enabled the kv-v2 secrets engine at: internal/
```

Put a username and password secret at the path `internal/exampleapp/config`:

```shell
$ vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
Key              Value
---              -----
created_time     2019-12-20T18:17:01.719862753Z
deletion_time    n/a
destroyed        false
version          1
```

Verify that the secret is defined at the path `internal/database/config`:

```shell
$ vault kv get internal/database/config
====== Metadata ======
Key              Value
---              -----
created_time     2019-12-20T18:17:50.930264759Z
deletion_time    n/a
destroyed        false
version          1

====== Data ======
Key         Value
---         -----
password    db-secret-password
username    db-readonly-username
```

## Configure Kubernetes authentication

Enable the Kubernetes authentication method:

```shell
/ $ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
```

Configure the Kubernetes authentication method to use the service account
token, the location of the Kubernetes host, and its certificate:

```shell
/ $ vault write auth/kubernetes/config \
        token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
        kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
Success! Data written to: auth/kubernetes/config
```

Write out the policy named `internal-app` that enables the `read` capability
for secrets at path `internal/data/database/config`

```shell
/ $ vault policy write internal-app - <<EOH
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOH
Success! Uploaded policy: internal-app
```

Create a Kubernetes authentication role named `internal-app`:

```shell
/ $ vault write auth/kubernetes/role/internal-app \
        bound_service_account_names=internal-app \
        bound_service_account_namespaces=default \
        policies=internal-app \
        ttl=24h
Success! Data written to: auth/kubernetes/role/internal-app
```

Lastly, exit the the `vault-0` pod:

```shell
/ $ exit
$
```

## Define a Kubernetes service account

The Vault Kubernetes authentication role defined a Kubernetes service account
named `internal-app`. This service acount does not yet exist.

Verify that the Kubernetes service account named `internal-app` does not exist:

```shell
$ kubectl get serviceaccounts
NAME                   SECRETS   AGE
default                1         43m
vault                  1         34m
vault-agent-injector   1         34m
```

View the service account defined in `exampleapp-service-account.yml`:

```shell
$ cat service-account-internal-app.yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: internal-app
```

Apply the service account definition to create it:

```shell
$ kubectl apply --filename service-account-internal-app.yml
serviceaccount/internal-app created
```

Verify that the service account has been created:

```shell
$ kubectl get serviceaccounts
NAME                   SECRETS   AGE
default                1         52m
internal-app           1         13s
vault                  1         43m
vault-agent-injector   1         43m
```

The name of the service account here aligns with the name assigned to the
`bound_service_account_names` field when creating the `internal-app` role
when configuring the Kubernetes authentication.

## Launch an application

View the deployment for the `orgchart` application:

```shell
$ cat deployment-01-orgchart.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orgchart
  labels:
    app: vault-agent-injector-demo
spec:
  selector:
    matchLabels:
      app: vault-agent-injector-demo
  replicas: 1
  template:
    metadata:
      annotations:
      labels:
        app: vault-agent-injector-demo
    spec:
      serviceAccountName: internal-app
      containers:
        - name: orgchart
          image: jweissig/app:0.0.1
```

Apply the deployment defined in `deployment-01-orgchart.yml`:

```shell
$ kubectl apply --filename deployment-01-orgchart.yml
deployment.apps/orgchart created
```

The application runs as a pod within the `default` namespace.

Get all the pods within the `default` namespace:

```shell
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
orgchart-69697d9598-l878s               1/1     Running   0          18s
vault-0                                 1/1     Running   0          58m
vault-agent-injector-5945fb98b5-tpglz   1/1     Running   0          58m
```

The orgchart deployment appears here as the pod named
`orgchart-69697d9598-l878s`.

Verify that no secrets are written to the `orgchart` container in the
`orgchart-69697d9598-l878s` pod:

```shell
$ kubectl exec orgchart-69697d9598-l878s --container orgchart -- ls /vault/secrets
ls: /vault/secrets: No such file or directory
command terminated with exit code 1
```

## Inject secrets into the pod

View the deployment patch `deployment-02-inject-secrets.yml`:

```shell
$ cat deployment-02-inject-secrets.yml
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "internal-app"
        vault.hashicorp.com/agent-inject-secret-database-config.txt: "internal/data/database/config"
```

Patch the `orgchart` deployment defined in `deployment-02-inject-secrets.yml`:

```shell
$ kubectl patch deployment orgchart --patch "$(cat deployment-02-inject-secrets.yml)"
deployment.apps/orgchart patched
```

Get all the pods within the `default` namespace:

```shell
$ kubectl get pods
NAME                                    READY   STATUS     RESTARTS   AGE
orgchart-599cb74d9c-s8hhm               0/2     Init:0/1   0          23s
orgchart-69697d9598-l878s               1/1     Running    0          20m
vault-0                                 1/1     Running    0          78m
vault-agent-injector-5945fb98b5-tpglz   1/1     Running    0          78m
```

View the logs of the `vault-agent` container in the `orgchart-599cb74d9c-s8hhm`
pod:

```shell
$ kubectl logs orgchart-599cb74d9c-s8hhm --container vault-agent
==> Vault server started! Log data will stream in below:

==> Vault agent configuration:

                     Cgo: disabled
               Log Level: info
                 Version: Vault v1.3.1

2019-12-20T19:52:36.658Z [INFO]  sink.file: creating file sink
2019-12-20T19:52:36.659Z [INFO]  sink.file: file sink configured: path=/home/vault/.token mode=-rw-r-----
2019-12-20T19:52:36.659Z [INFO]  template.server: starting template server
2019/12/20 19:52:36.659812 [INFO] (runner) creating new runner (dry: false, once: false)
2019/12/20 19:52:36.660237 [INFO] (runner) creating watcher
2019-12-20T19:52:36.660Z [INFO]  auth.handler: starting auth handler
2019-12-20T19:52:36.660Z [INFO]  auth.handler: authenticating
2019-12-20T19:52:36.660Z [INFO]  sink.server: starting sink server
2019-12-20T19:52:36.679Z [INFO]  auth.handler: authentication successful, sending token to sinks
2019-12-20T19:52:36.680Z [INFO]  auth.handler: starting renewal process
2019-12-20T19:52:36.681Z [INFO]  sink.file: token written: path=/home/vault/.token
2019-12-20T19:52:36.681Z [INFO]  template.server: template server received new token
2019/12/20 19:52:36.681133 [INFO] (runner) stopping
2019/12/20 19:52:36.681160 [INFO] (runner) creating new runner (dry: false, once: false)
2019/12/20 19:52:36.681285 [INFO] (runner) creating watcher
2019/12/20 19:52:36.681342 [INFO] (runner) starting
2019-12-20T19:52:36.692Z [INFO]  auth.handler: renewed auth token
```

Vault Agent manages the token lifecycle and the secret retrieval. The secret is
rendered in the `orgchart` container at the path
`/vault/secrets/database-config.txt`.

Finally, view the secret written to the `orgchart` container:

```shell
$ kubectl exec orgchart-599cb74d9c-s8hhm --container orgchart -- cat /vault/secrets/database-config.txt
data: map[password:db-secret-password username:db-readonly-user]
metadata: map[created_time:2019-12-20T18:17:50.930264759Z deletion_time: destroyed:false version:2]
```

The secret is present on the container. However, the structure is not in one
expected by the application.

## Apply a template to the injected secrets

View the annotations file that contains a template definition:

```shell
$ cat deployment-03-inject-secrets-as-template.yml
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/role: "internal-app"
        vault.hashicorp.com/agent-inject-secret-database-config.txt: "internal/data/database/config"
        vault.hashicorp.com/agent-inject-template-database-config.txt: |
          {{- with secret "internal/data/database/config" -}}
          postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@postgres:5432/wizard
          {{- end -}}
```

Apply the updated annotations:

```shell
$ kubectl patch deployment orgchart --patch "$(cat deployment-03-inject-secrets-as-template.yml)"
deployment.apps/exampleapp patched
```

Get all the pods within the `default` namespace:

```shell
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
orgchart-554db4579d-w6565               2/2     Running   0          16s
vault-0                                 1/1     Running   0          126m
vault-agent-injector-5945fb98b5-tpglz   1/1     Running   0          126m
```

Finally, view the template written to the `orgchart` container:

```shell
$ kubectl exec -it orgchart-554db4579d-w6565 -c orgchart -- cat /vault/secrets/database-config.txt
postgresql://db-readonly-user:db-secret-password@postgres:5432/wizard
```

## Deployment with annotations

View the deployment for the `payrole` application:

```shell
$ cat deployment-04-payrole.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payrole
  labels:
    app: vault-agent-injector-demo
spec:
  selector:
    matchLabels:
      app: vault-agent-injector-demo
  replicas: 1
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/role: "internal-app"
        vault.hashicorp.com/agent-inject-secret-database-config.txt: "internal/data/database/config"
        vault.hashicorp.com/agent-inject-template-database-config.txt: |
          {{- with secret "internal/data/database/config" -}}
          postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@postgres:5432/wizard
          {{- end -}}
      labels:
        app: vault-agent-injector-demo
    spec:
      serviceAccountName: internal-app
      containers:
        - name: payrole
          image: jweissig/app:0.0.1
```

Apply the deployment defined in `deployment-04-payrole.yml`:

```shell
$ kubectl apply --filename deployment-04-payrole.yml
deployment.apps/payrole created
```

Get all the pods within the `default` namespace:

```shell
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
orgchart-554db4579d-w6565               2/2     Running   0          29m
payrole-7dc758dc7b-9dc6t                2/2     Running   0          12s
vault-0                                 1/1     Running   0          155m
vault-agent-injector-5945fb98b5-tpglz   1/1     Running   0          155m
```

Finally, view the template rendered to the `payrole` container:

```shell
$ kubectl exec payrole-7dc758dc7b-9dc6t --container payrole -- cat /vault/secrets/database-config.txt
postgresql://db-readonly-user:db-secret-password@postgres:5432/wizard
```

## Secrets are bound to the service account

Attempts to run a pod with a different service account than the ones listed in
the authentication are not be able to access the secrets defined at that path.

View the deployment and service account for the `website` application:

```shell
$ cat deployment-05-website.yml
```

Apply the deployment and service account defined in `deployment-05-website.yml`:

```shell
$ kubectl apply --filename deployment-05-website.yml
deployment.apps/website created
serviceaccount/external-app created
```

Get all the pods within the `default` namespace:

```shell
$ kubectl get pods
NAME                                    READY   STATUS     RESTARTS   AGE
orgchart-554db4579d-w6565               2/2     Running    0          29m
payrole-7dc758dc7b-9dc6t                2/2     Running    0          12s
vault-0                                 1/1     Running    0          155m
vault-agent-injector-5945fb98b5-tpglz   1/1     Running    0          155m
website-7fc8b69645-527rf                0/2     Init:0/1   0          76s
```

The website deployment creates a pod but it does not ever become ready.

View the logs of the `vault-agent-init` container in the
`website-7fc8b69645-527rf` pod:

```shell
$ kubectl logs website-7fc8b69645-527rf --container vault-agent-init
...
2019-12-20T21:36:32.825Z [INFO]  auth.handler: authenticating
2019-12-20T21:36:32.830Z [ERROR] auth.handler: error authenticating: error="Error making API request.

URL: PUT http://vault.default.svc:8200/v1/auth/kubernetes/login
Code: 500. Errors:

* service account name not authorized" backoff=1.562132589
```

The initialization process is failing because the service account name is not
authorized. The service account, `external-app` is not assigned to any Vault
Kubernetes authentication role preventing the initialization to complete.

## Secrets are bound to the namespace

Similar to how the secrets are bound to a service account they are also bound
to a namespace.

Create the `offsite` namespace:

```shell
$ kubectl create namespace offsite
namespace/offsite created
```

Set the current context to the offsite namespace:

```shell
$ kubectl config set-context --current --namespace offsite
Context "minikube" modified.
```

Apply the deployment and creat the service account defined in
`deployment-06-issues.yml`:

```shell
$ kubectl apply --filename deployment-06-issues.yml
deployment.apps/issues created
serviceaccount/internal-app created
```

Get all the pods within the `offsite` namespace:


```shell
$ kubectl get pods
NAME                      READY   STATUS     RESTARTS   AGE
issues-7956fff46d-9kzv6   0/2     Init:0/1   0          40s
```

-> **Current context:** The same command is issued but the results are different
  because you are now in a different namespace.

The issues deployment creates a pod but it does not ever become ready.

View the logs of the `vault-agent-init` container in the
`issues-7956fff46d-9kzv6` pod:

```shell
$ kubectl logs issues-7956fff46d-9kzv6 --container vault-agent-init
...
2019-12-20T21:43:41.293Z [INFO]  auth.handler: authenticating
2019-12-20T21:43:41.296Z [ERROR] auth.handler: error authenticating: error="Error making API request.

URL: PUT http://vault.default.svc:8200/v1/auth/kubernetes/login
Code: 500. Errors:

* namespace not authorized" backoff=1.9882590740000001
```

The initialization process is failing because the namespace is not authorized.
The namespace, `offsite` is not assigned to any Vault Kubernetes authentication
role preventing the initialization to complete.
