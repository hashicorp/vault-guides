# Vault Agent with Kubernetes

These assets are provided to perform the steps described in the [Vault Agent with Kubernetes](https://learn.hashicorp.com/vault/identity-access-management/vault-agent-k8s) guide.

---

**NOTE:** For the purpose of demonstration, this guide runs Minikube as a
Kubernetes environment. If you already have a running Kubernetes environment
in a cloud, you can use that instead.

## Prerequisites

To perform the tasks described in this guide, you need:

- [Minikube installed](https://kubernetes.io/docs/tasks/tools/install-minikube/)
- A running Vault environment reachable from your Kubernetes environment
- [Key/Value secrets engine version 1](https://www.vaultproject.io/docs/secrets/kv/kv-v1.html) is mounted at `secret/`

> If you want to test against Azure Kubernetes Service (AKS) cluster or Google Kubernetes Engine (GKE) cluster instead, you can use the Terraform files under the `terraform-azure` folder to create an AKS cluster or the `terraform-gcp` folder for a GKE cluster. Refer to the [guide](https://learn.hashicorp.com/vault/identity-access-management/vault-agent-k8s#azure-kubernetes-service-cluster) for more detail.

## Demo Steps

1. Make sure that Minikube has been started: `minikube start`

1.  Run the `setup-k8s-auth.sh` script to set up the kubernetes auth method on your Vault server.

    **NOTE:** This guide assumes that _version 1_ of `kv` secret engine is mounted at `secret/`. If it is not enabled, un-comment the line 27 in the `setup-k8s-auth.sh` file.

    ```plaintext
    $ ./setup-k8s-auth.sh
    ```

1. Open the `example-k8s-spec.yml` and be sure to set the correct `VAULT_ADDR` value ***if*** your Vault server is NOT running locally (line 43 and 74).

    **Example:**

    ```plaintext
    ...
    initContainers:
      # Vault container
      - name: vault-agent-auth
        image: vault

        ...

        # This assumes Vault running on local host and K8s running in Minikube using VirtualBox
        env:
          - name: VAULT_ADDR
            value: http://192.0.2.5:8200
      ...

      containers:
        # Consul Template container
        - name: consul-template
          image: hashicorp/consul-template:alpine
          imagePullPolicy: Always

          ...

          env:
            - name: HOME
              value: /home/vault

            - name: VAULT_ADDR
              value: http://192.0.2.5:8200
        ...
    ```

1. Now, create a Pod using ConfigMap named, `example-vault-agent-config` pulling files from `configs-k8s` directory:

    ```shell
    # Create a ConfigMap, example-vault-agent-config
    $ kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/

    # View the created ConfigMap
    $ kubectl get configmap example-vault-agent-config -o yaml

    # Finally, create vault-agent-example Pod
    $ kubectl apply -f example-k8s-spec.yml --record
    ```

    This takes a minute or so for the Pod to become fully up and running.


### Verification

Open another terminal and launch the Minikube dashboard: `minikube dashboard`

1. Click **Pods** under **Workloads** to verify that `vault-agent-example` Pod has
been created successfully.

1. Select **vault-agent-example** to see its details.

1. Now, port-forward so you can connect to the client from browser:

    ```plaintext
    $ kubectl port-forward pod/vault-agent-example 8080:80
    ```

    In a web browser, go to `localhost:8080`

    Notice that the `username` and `password` values were successfully read from
    `secret/myapp/config`.

1. Open a shell of `vault-agent-auth` container:

    ```plaintext
    $ kubectl exec -it vault-agent-example --container vault-agent-auth sh
    ```

    Remember that the Vault Agent's `sink` is set to `/home/vault/.vault-token`.
    To view the token stored in the sink:

    ```plaintext
    /# echo $(cat /home/vault/.vault-token)
    s.7MQZzFZxUTBQMrtfy98wTGkZ
    ```

    Enter `exit` to terminate the shell.

1. Optionally, you can view the HTML source:

    ```plaintext
    $ kubectl exec -it vault-agent-example --container nginx-container sh

    /# cat /usr/share/nginx/html/index.html
      <html>
      <body>
      <p>Some secrets:</p>
      <ul>
      <li><pre>username: appuser</pre></li>
      <li><pre>password: suP3rsec(et!</pre></li>
      </ul>

      </body>
      </html>
    ```

## Troubleshooting

If `localhost:8080` returns an error, check the following:

1. Verify that the `kubernetes` auth method is working
1. Verify that the `consul-template` can read the token from `/home/vault/.vault-token`

### Kubernetes auth method verification

Follow the steps documented in the [Step 3: Verify the Kubernetes auth method configuration](https://learn.hashicorp.com/vault/identity-access-management/vault-agent-k8s#step-3-verify-the-kubernetes-auth-method-configuration).


### Examine the consul-template container

Open a shell of `consul-template` container:

```plaintext
$ kubectl exec -it vault-agent-example --container consul-template sh
```

Remember that the Vault Agent's `sink` is set to `/home/vault/.vault-token`.
To view the token stored in the sink:

```plaintext
/# echo $(cat /home/vault/.vault-token)
s.7MQZzFZxUTBQMrtfy98wTGkZ
```

If it fails to read a token, this may be related to an [issue](https://github.com/hashicorp/vault-guides/issues/100) reported. Some suggested to use a different `consul-template` Docker image [tag](https://hub.docker.com/r/hashicorp/consul-template/tags):

- `hashicorp/consul-template:0.19.6-dev-alpine`
- `registry.hub.docker.com/sethvargo/consul-template:0.19.5.dev-alpine`

To run a different image, modify line 56 in the `example-k8s-spec.yml` file to load a different `consul-template` image:

**Example:**

```plaintext
...
containers:
  # Consul Template container
  - name: consul-template
    image: hashicorp/consul-template:0.19.6-dev-alpine
    imagePullPolicy: Always
...
```
