# Vault Agent Demo

These assets are provided to provision AWS resources to perform the steps described in the [Vault Agent](https://deploy-preview-290--hashicorp-learn.netlify.com/vault/identity-access-management/vault-agent-k8s) guide.

---

**NOTE:** For the purpose of demonstration, this guide runs Minikube as a
Kubernetes environment. If you already have a running Kubernetes environment
in a cloud, you can use that instead.

## Prerequisites

To perform the tasks described in this guide, you need:

- [Minikube installed](https://kubernetes.io/docs/tasks/tools/install-minikube/)
- A running Vault environment reachable from your Kubernetes environment


## Demo Steps

1. Make sure that Minikube has been started: `minikube start`

1. Create a Kubernetes Service Account to use for this guide:

    ```shell
    # Create a service account, 'vault-auth'
    $ kubectl create serviceaccount vault-auth

    # Update the 'vault-auth' service account
    $ kubectl apply --filename vault-auth-service-account.yml
    ```

1.  Create a read-only policy, `myapp-kv-ro` in Vault.

    ```shell
    # Create a policy file, myapp-kv-ro.hcl
    $ tee myapp-kv-ro.hcl <<EOF
    path "secret/myapp/*" {
        capabilities = ["read", "list"]
    }
    EOF

    # Create a policy named myapp-kv-ro
    $ vault policy write myapp-kv-ro myapp-kv-ro.hcl
    ```

    **NOTE:** Since Consul Template does not support K/V v2 at the
    moment, this guide assumes that [Key/Value **version
    1**](https://www.vaultproject.io/api/secret/kv/kv-v1.html) secret engine is
    enabled at `secret/`

1.  Create test data in the `secret/myapp` path.

    ```plaintext
    $ vault kv put secret/myapp/config username='appuser' \
            password='suP3rsec(et!' \
            ttl='30s'
    ```

1.  Create a user to test the `myapp-kv-ro` policy using `userpass` auth method.

    ```shell
    # Enable userpass auth method
    $ vault auth enable userpass

    # Create a user named "test-user"
    $ vault write auth/userpass/users/test-user \
            password=training \
            policies=myapp-kv-ro
    ```

1.  Now, enable and [configure the Kubernetes auth method](https://www.vaultproject.io/docs/auth/kubernetes.html#configuration).

    ```shell
    # Set VAULT_SA_NAME to the service account you created earlier
    $ export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")

    # Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
    $ export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

    # Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
    $ export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

    # Set K8S_HOST to minikube IP address
    $ export K8S_HOST=$(minikube ip)

    # Enable the Kubernetes auth method at the default path ("auth/kubernetes")
    $ vault auth enable kubernetes

    # Tell Vault how to communicate with the Kubernetes (Minikube) cluster
    $ vault write auth/kubernetes/config \
            token_reviewer_jwt="$SA_JWT_TOKEN" \
            kubernetes_host="https://$K8S_HOST:8443" \
            kubernetes_ca_cert="$SA_CA_CRT"

    # Create a role named, 'example' to map Kubernetes Service Account to
    #  Vault policies and default token TTL
    $ vault write auth/kubernetes/role/example \
            bound_service_account_names=vault-auth \
            bound_service_account_namespaces=default \
            policies=myapp-kv-ro \
            ttl=24h
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

    ```shell
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

For more detailed instruction, refer to the [Vault Agent with Kubernetes](https://deploy-preview-290--hashicorp-learn.netlify.com/vault/identity-access-management/vault-agent-k8s) guide. 
