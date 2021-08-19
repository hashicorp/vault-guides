# vault-plugin-secrets-hashicups

This secrets engine renews and revokes JSON Web Tokens (JWTs)
for the HashiCorp demo application.
## Prerequisites

1. Target API with CRUD capabilities for secrets.
1. Golang 1.16+
1. Docker &  Docker Compose 20.10+
1. Terraform 1.0+
1. Google Cloud Platform

## Install

1. Run `go mod init`.

1. Build the secrets engine into a plugin using Go.
   ```shell
   $ go build -o vault/plugins/vault-plugin-secrets-hashicups cmd/vault-plugin-secrets-hashicups/main.go
   ```

1. You can find the binary in `vault/plugins/`.
   ```shell
   $ ls vault/plugins/
   ```

1. Run a Vault server in `dev` mode to register and try out the plugin.
   ```shell
   $ vault server -dev -dev-root-token-id=root -dev-plugin-dir=./vault/plugins
   ```

## Start the HashiCorp Demo Application

The [HashiCorp Demo Application](https://github.com/hashicorp-demoapp)
includes a set of services that run
an online coffee store. In this demo, we use two of these services:

- A products database, which stores information about coffee and
  user logins.
- A products API, which returns information about coffee, ingredients,
  and handles user logins.

1. Go to the `terraform` directory. It includes configuration files
   to create a Kubernetes cluster.
   ```shell
   cd terraform && terraform init && terraform apply
   ```

1. Start the HashiCorp Demo Application in Kubernetes.
   ```shell
   kubectl apply -f kubernetes/
   ```

1. You should have started two containers.
   ```shell
   $ kubectl get deployments

   NAME          READY   UP-TO-DATE   AVAILABLE   AGE
   postgres      1/1     1            1           91s
   product-api   1/1     1            1           90s
   ```

You can access the products API
on `http://$(kubectl get service product-api  -o jsonpath="{.status.loadBalancer.ingress[*].ip}"):9090`.

We'll be using specific API endpoints related to user
logins in the [products API](https://github.com/hashicorp-demoapp/product-api-go).

| PATH | METHOD | DESCRIPTION | HEADER | REQUEST | RESPONSE |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| /signup | POST | Create a new user with a password. | | `{"username": "user", "password": "pass"}` | `{"UserID":1,"Username":"user","token":"<JWT>"}` |
| /signin | POST | Sign in an existing user and return an API token in the form of a JWT | | `{"username": "user", "password": "pass"}` | `{"UserID":1,"Username":"user","token":"<JWT>"}` |
| /signout | POST | Sign out a user based on their API token | `Authorization:<JWT>` | | `Signed out user` |

## Additional references:

- [Upgrading Plugins](https://www.vaultproject.io/docs/upgrading/plugins)
- [List of Vault Plugins](https://www.vaultproject.io/docs/plugin-portal)