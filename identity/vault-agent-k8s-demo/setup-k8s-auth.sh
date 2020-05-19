#!/bin/bash

# Create a service account, 'vault-auth'
kubectl create serviceaccount vault-auth

# Update the 'vault-auth' service account
kubectl apply --filename vault-auth-service-account.yml

# Start a Vault server in dev mode
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200

# Set the VAULT_ADDR environment variable
export VAULT_ADDR=http://0.0.0.0:8200

# Create a policy file, myapp-kv-ro.hcl
# This assumes that the Vault server is running kv v1 (non-versioned kv)
tee myapp-kv-ro.hcl <<EOF
path "secret/data/myapp/*" {
    capabilities = ["read", "list"]
}
EOF

# Create a policy named myapp-kv-ro
vault policy write myapp-kv-ro myapp-kv-ro.hcl

# Enable K/V v1 at secret/ if it's not already available
# vault secrets enable -path=secret kv

# Create test data in the `secret/myapp` path.
vault kv put secret/myapp/config username='appuser' password='suP3rsec(et!' ttl='30s'

# Enable userpass auth method
vault auth enable userpass

# Create a user named "test-user"
vault write auth/userpass/users/test-user password=training policies=myapp-kv-ro

# Set VAULT_SA_NAME to the service account you created earlier
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")

# Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

# Set K8S_HOST to minikube IP address
export K8S_HOST=$(minikube ip)

# Enable the Kubernetes auth method at the default path ("auth/kubernetes")
vault auth enable kubernetes

# Tell Vault how to communicate with the Kubernetes (Minikube) cluster
vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="https://$K8S_HOST:8443" kubernetes_ca_cert="$SA_CA_CRT"

# Create a role named, 'example' to map Kubernetes Service Account to
#  Vault policies and default token TTL
vault write auth/kubernetes/role/example bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=myapp-kv-ro ttl=24h
