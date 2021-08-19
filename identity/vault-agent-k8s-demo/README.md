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

1. Run the `setup-k8s-auth.sh` script to set up the kubernetes auth method on your Vault server.

    **NOTE:** This guide assumes that _version 1_ of `kv` secret engine is mounted at `secret/`. If it is not enabled, un-comment the line 27 in the `setup-k8s-auth.sh` file.

    ```plaintext
    $ ./setup-k8s-auth.sh
    ```

1. Start a minikube SSH session.

    ```shell
    $ minikube ssh
    ```

1. Within this SSH session, retrieve the value of the Minikube host.

    ```shell
    $ route -n | grep ^0.0.0.0 | awk '{ print $2 }'
    192.168.64.1
    ```

    In this example, the Vault address would be **`http://192.168.64.1:8200`**.

    Enter `exit` to quit the SSH session.

1. Open the `example-k8s-spec.yaml` and be sure to set the correct `VAULT_ADDR` value for your environment.

1. Now, create a Pod using ConfigMap named, `example-vault-agent-config` pulling files from `configs-k8s` directory:

    ```shell
    # Create a ConfigMap, example-vault-agent-config
    $ kubectl create -f configmap.yaml

    # View the created ConfigMap
    $ kubectl get configmap example-vault-agent-config -o yaml

    # Finally, create vault-agent-example Pod
    $ kubectl apply -f example-k8s-spec.yaml --record
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


Follow the [Vault Agent with Kubernetes](https://learn.hashicorp.com/vault/identity-access-management/vault-agent-k8s) guide for a step-by-step instruction. 
