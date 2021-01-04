# Demonstrate the Kubernetes Auth method

This guide will demonstrate how an application in Kubernetes can login to Vault using the [Kubernetes Auth method](https://www.vaultproject.io/docs/auth/kubernetes.html) and read secrets. The application will be deployed in a non-default Kubernetes Namespace and will retrieve a secret from the Key/Value Secrets Engine. 

This demo will also cover how to use Vault's [ACL Policy Path Templating](https://learn.hashicorp.com/tutorials/vault/policy-templating) feature to create a repeatable approach of onboarding additional applications to Vault.

The application used in this demo is a simple Golang application that uses Vault's Go SDKs to interact with Vault directly. **Important: the application is for demo purposes only and not suitable for use in production.**

## Pre-requisites
1. Vault server (>0.9.0), and a root or administrative token. There are a few ways to deploy Vault, below are some options. 
  - To deploy a Vault server on Kubernetes, please see the [Running Vault with Kubernetes](https://learn.hashicorp.com/tutorials/vault/kubernetes-minikube) documentation. This demo assumes that Vault is deployed on Kubernetes and the `VAULT_ADDR` environment variable is set to Vault service name: `http://vault-k8s.default.svc.cluster.local:8200` in the application deployment.yaml file.  
  - To deploy a Vault server on a VM please see the [Vault getting started guide](https://learn.hashicorp.com/vault/getting-started/deploy). 
  - You can also quickly deploy it using Docker as shown below:
```
docker rm -f dev-vault
docker run -p 8200:8200 --cap-add=IPC_LOCK \
  -e 'VAULT_DEV_ROOT_TOKEN_ID=devroottoken' \
  -d --name=dev-vault "vault:1.6.1"
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="devroottoken"
vault status
```
2. An existing Kubernetes cluster or Minikube installation. This guide has beek tested on GKE and OpenShift.
3. Connectivity between Vault Server and Kubernetes. 
4. The `ca.crt` file from Kubernetes cluster creation.

Example validation commands:
```bash
vault --version
# Ensure VAULT_ADDR and VAULT_TOKEN environment variables are exported correctly:
vault token lookup
kubectl cluster-info
kubectl get nodes
```

## Steps
Please git clone this repo and change to the `identity/kubernetes-auth-demo` sub-directory as noted below to get started.
```bash
git clone https://github.com/hashicorp/vault-guides.git
cd identity/kubernetes-auth-demo/
```

This guide is broken into a few sub-sections. Please review and follow the steps in order.
1. [Configure Kubernetes](#step1)
2. [Configure Vault server](#step2)
3. [Deploy the application](#step3)
4. [Deploy additional applications](#step4)

### <a name="step1"></a> 1. Configure Kubernetes
As a first step, we will save the Kubernetes API server endpoint as an environment variable as this will be needed during the Authentication method setup.
```bash
# Set the Kubernetes API server
export K8S_API_SERVER=$(TERM=dumb kubectl cluster-info | awk '/master/ {print $NF}')
```

#### Create the vault-reviewer Service Account
The Kubernetes Authentication method has a `token_reviewer_jwt` field which takes a Service Account token that is in charge of verifying the validity of other service account tokens. This Service Account will call the [Kubernetes TokenReview API](https://www.k8sref.io/docs/authentication/tokenreview-v1/) and verify that the service account tokens provided during logins are valid. We will start by creating a service account called `vault-reviewer` that can be used by Vault to call this API.

Please issue the following commands from the `kubernetes-auth-demo` directory to create the `vault-reviewer` service account and provide it with an RBAC role to give it access to the TokenReview API. We will also save the JWT associated with the service account into an environment variable.
```bash
# Create vault reviewer service account and assign RBAC role
kubectl create -f vault-reviewer.yaml
kubectl create -f vault-reviewer-rbac.yaml

# Obtain the JWT for Vault reviewer service account
export VAULT_SA_NAME=$(kubectl get sa vault-reviewer -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

# Save the ca.crt file
kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode > ca.crt
export CA_CRT_PATH=./ca.crt

# Optional: display the CA certificate
openssl x509 -in ${CA_CRT_PATH} -text -noout
```

- Note: `vault-reviewer-rbac.yaml` creates a Kubernetes `ClusterRoleBinding` for the `vault-reviewer` service account for the `system:auth-delegator` ClusterRole. To view the permissions of this role, please issue: `kubectl describe ClusterRole system:auth-delegator`. You will notice PolicyRule that allows tokenreview and subjectaccessreview API calls.

#### Create application namespace and service accounts
We will name the demo application `app1` and it deploy it in the Kubernetes Namespace called `retail`. We are assuming that a Namespace corresponds to a Line-of-Business (LOB). Please create a service account for this application and the Namespace as shown below.
```bash
export ns="retail"
export app="app1"
kubectl create ns ${ns}
kubectl create sa ${app} -n ${ns}
```

### <a name="step2"></a> 2. Configure Vault
If you have not done so already, please export the `VAULT_ADDR` and `VAULT_TOKEN` environment variables and ensure connectivity. Then enable the Vault audit logs as this will help us later on to confirm that the authentication workflow is working as expected.
```bash
# Export variables
export VAULT_ADDR="http://vault_server_dns:8200"
export VAULT_TOKEN=root_or_admin_token
vault status
vault token lookup

# Enable the audit log (adjust the audit log file path appropriately)
vault audit enable file file_path=/tmp/audit_log.json
```

#### Enable the Kubernetes Authentication Method
The default path for the Kubernetes Auth Method is `kubernetes`, but we will make it specific to a cluster name, since each cluster has a different API endpoint. Please adjust the `cluster_name` variable as needed.
```bash
# export cluster_name="docker-k8s"
export cluster_name="gke-useast1"
vault auth enable -path=${cluster_name} kubernetes
vault write auth/${cluster_name}/config \
    token_reviewer_jwt=${SA_JWT_TOKEN}  \
    kubernetes_host=${K8S_API_SERVER} \
    kubernetes_ca_cert=@${CA_CRT_PATH}
```

### <a name="step3"></a> 3. Deploy the application
In this step we will configure an Role for the application under the Authentication method. Then we will deploy the application and test that the login and secret retrieval process is successful. 

#### Create an application policy and role
Roles are used to bind Kubernetes Service Account names and namespaces to a set of Vault policies and token settings. Please issue the commands below to create an ACL policy called `app1-policy`. We will then map the policy to an application specific Role. Note that we will change directory first to `basic-example/`.
```bash
cd basic-example/

# Ensure that the app and namespace variables are set to app1 and retail
echo ${app} && echo ${ns}

# View the app policy file and create the policy
cat ${app}-policy.hcl
vault policy write ${app}-policy ${app}-policy.hcl

# Create the application role
vault write auth/${cluster_name}/role/${ns}-${app} \
    bound_service_account_names=${app} \
    bound_service_account_namespaces=${ns} \
    policies=${app}-policy \
    period=120s
```
A few notes:
- In the above snippet, the application and Namespace names are designated as variables. This will allow a scripting based approach to onboard additional apps.
- On the Role, we have set a period of 120 seconds; this means the resulting token is a [periodic token](https://www.vaultproject.io/docs/concepts/tokens.html#periodic-tokens) and must be renewed by the application at least every 120s.

#### Write an application secret
Please issue the commands below to mount the KV version 1 engine and write a static secret that will be read by the application. Note that we are mounting the secret engine at a path where there will be one secret engine per Kubernetes Namespace.
```bash
# Mount the kv secrets engine
vault secrets enable -path=kv/${ns} -version=1 kv
vault write kv/${ns}/${app} app=${app} username=demo password=test
```

Create a token with the `app1-policy` to ensure we can read the above path as below:
```bash
token=$(vault token create -format=json -policy=${app}-policy | jq -r .auth.client_token)
VAULT_TOKEN=$token vault read kv/${ns}/${app}
```
The output from the vault read command should be similar to below.
```
Key                 Value
---                 -----
refresh_interval    768h
app                 app1
password            test
username            demo
```

#### Deploy the application
Please create a Kubernetes Deployment object for our application as shown below. We will substitute various identifiers for the Deployment based on the Namespace and application names. Please open the resulting yaml file and ensure that all of the fields are correct including `VAULT_ADDR`. 

Note that by default the application image will be sourced from Dockerhub: `kawsark/vault-example-init:0.0.8`. If you prefer to build an image on your own, please see the steps in [app/build.md](app/build.md) and update the `image:` property in the deployment.yaml file.

```bash
# Create the app deployment yaml file with a set of substitutions
cat deployment-template.yaml | sed  -e s/"my-deployment"/"${app}-deployment"/ \
                                  -e s/"my-namespace"/${ns}/ \
                                  -e s/"my-app-name"/"basic-example-${app}"/g \
                                  -e s/"my-app-sa"/${app}/ \
                                  -e s/"secret-path"/"kv\/${ns}\/${app}"/ \
                                  -e s/"login-path"/"auth\/${cluster_name}\/login"/ \
                                  -e s/"my-role"/"${ns}-${app}"/ > deployment-$ns-$app.yaml 

# Display the deployment file to ensure all the fields are correct
cat deployment-$ns-$app.yaml 

# Create the application and display pods
kubectl create -f deployment-$ns-$app.yaml
kubectl get pods -n ${ns}
```

#### View the application logs
This application will read the servcie account JWT token and use it to authenticate with Vault. It will then log the secret (do **not** log secrets in a real application!) and keep the token renewed.

```bash
export pod_name=$(kubectl get pods -l app=basic-example-${app} -o jsonpath='{.items[0].metadata.name}' -n ${ns})
kubectl logs ${pod_name} -n ${ns}
```

You should see log output similar to:
```
2021/01/04 14:12:42 ==> WARNING: Don't ever write secrets to logs.
2021/01/04 14:12:42 ==>          This is for demonstration only.
2021/01/04 14:12:42 s.6oV7pIDnB7AQUZO6a4dIzKyF
2021/01/04 14:12:42 secret kv/retail/app1 -> &{2e83c248-69f7-70a2-e6cb-7d70e6ce7b9e  2764800 false map[app:app1 password:test username:demo] [] <nil> <nil>}
2021/01/04 14:12:42 Starting renewal loop
2021/01/04 14:12:42 Successfully renewed: &api.RenewOutput{RenewedAt:time.Time{wall:0x31698fdc, ext:63745366362, loc:(*time.Location)(nil)}, Secret:(*api.Secret)(0xc00006d3e0)}
```

Then you should see a token renewal and secret read happen approximately every 120s. 

#### 4. Troubleshooting
In case you are getting errors above, its helpful to try the login process using Vault CLI. Use the commands below to export the application JWT, then login and read the secret from Vault.

```bash
# Export applicatin jwt
export jwt=$(kubectl exec ${pod_name} -n ${ns} -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Login to vault
vault write -format=json auth/${cluster_name}/login \
 jwt=${jwt} \
 role=${ns}-${app} > login.json

# Inspect the output from login request
cat login.json

# Use the Vault token to read the secret
token=$(cat login.json | jq -r .auth.client_token)
VAULT_TOKEN=$token vault read kv/${ns}/${app}
```

### <a name="step4"></a> 4. Deploying additional applications
As you noted above, we needed to create a specific policy for our application. This can cause high policy management overhead when onboarding 100s of applications to Vault. In this step we will use a templetized approach using [Vault ACL Policy Path templates](https://learn.hashicorp.com/tutorials/vault/policy-templating#step-1-write-templated-acl-policies) to define a single policy per cluster for all applications.

#### Create templetized policy and re-test app1
Use the commands below to create a templetized policy where Vault will dynamically substitute the Namespace and Application service account names.
```bash
# Save the mount accessor ID
mount_accessor=$(vault auth list | grep ${cluster_name} | awk '{print $3}')

# Write the templated ACL policy
vault policy write ${cluster_name}-kv-read - << EOF
path "kv/{{identity.entity.aliases.${mount_accessor}.metadata.service_account_namespace}}/{{identity.entity.aliases.${mount_accessor}.metadata.service_account_name}}" {
      capabilities=["read", "list"] }
EOF

# Associate policy with Role
vault write auth/${cluster_name}/role/${ns}-${app} \
    bound_service_account_names=${app} \
    bound_service_account_namespaces=${ns} \
    policies=${cluster_name}-kv-read \
    period=120s
```

Redeploy the application to ensure it is able to login and read secrets using the new policy. 
```bash
kubectl delete -f deployment-$ns-$app.yaml
kubectl create -f deployment-$ns-$app.yaml

# Read application logs similar to before
export pod_name=$(kubectl get pods -l app=basic-example-${app} -o jsonpath='{.items[0].metadata.name}' -n ${ns})
kubectl logs ${pod_name} -n ${ns}
```

If you view the Vault audit logs, you should see an entry showing a successful login that maps to the `<cluster_name>-kv-read` policy, followed by a KV read.
```bash
# Adjust the audit path 
tail /vault/audit/audit_log.txt

# Authentication
{"time":"2021-01-04T16:10:45.881794702Z","type":"response","auth":{"client_token":"hmac-sha256:97aaf5c989fe2d300c36b5bda89bf69ad34fc30f79e6714f626db461c9093936","accessor":"hmac-sha256:0363a79b20d9a08c7faf30ca6d07b9821ed08a875866b6b74cd54802a1076c5d","display_name":"gke-useast1-retail-app1","policies":["default","gke-useast1-kv-read"],"token_policies":["default","gke-useast1-kv-read"],"metadata":{"role":"retail-app1-template","service_account_name":"app1","service_account_namespace":"retail","service_account_secret_name":"app1-token-x4npd","service_account_uid":"c0fed346-308e-4bdf-a18c-f9d0e8ea4639"},"entity_id":"6021bd59-6f00-e459-3c69-21cc25fb871c","token_type":"service","token_ttl":120},"request":{"id":"164ef954-a246-b6bc-9b12-ae69b3c5e1d7","operation":"update","mount_type":"kubernetes","namespace":{"id":"root"},"path":"auth/gke-useast1/login","data":

# Secret Access attempt
{"time":"2021-01-04T16:13:40.21441436Z","type":"response","auth":{"client_token":"hmac-sha256:97aaf5c989fe2d300c36b5bda89bf69ad34fc30f79e6714f626db461c9093936","accessor":"hmac-sha256:0363a79b20d9a08c7faf30ca6d07b9821ed08a875866b6b74cd54802a1076c5d","display_name":"gke-useast1-retail-app1","policies":["default","gke-useast1-kv-read"],"token_policies":["default","gke-useast1-kv-read"],"metadata":{"role":"retail-app1-template","service_account_name":"app1","service_account_namespace":"retail","service_account_secret_name":"app1-token-x4npd","service_account_uid":"c0fed346-308e-4bdf-a18c-f9d0e8ea4639"},"entity_id":"6021bd59-6f00-e459-3c69-21cc25fb871c","token_type":"service","token_ttl":120,"token_issue_time":"2021-01-04T16:10:45Z"},"request":{"id":"1db4fd9e-86d5-b491-5f53-4a0fb693439e","operation":"read","mount_type":"kv","client_token":"hmac-sha256:97aaf5c989fe2d300c36b5bda89bf69ad34fc30f79e6714f626db461c9093936","client_token_accessor":"hmac-sha256:0363a79b20d9a08c7faf30ca6d07b9821ed08a875866b6b74cd54802a1076c5d","namespace":{"id":"root"},"path":"kv/retail/app1","remote_address":"10.84.3.21"},"response":{"mount_type":"kv","secret":{},"data":{"app":"hmac-sha256:7af4ccfd74db42c23fa42930183a7959b9b55fe26de427f6aeab427e7a4faa04","password":"hmac-sha256:da5ff1936539df45a2a1c3f8a1c8d905905662c2fd8da58652383f5c04f86d31","username":"hmac-sha256:ff948a5ec9b2577505e51cfb5541a424d22be54da3a1f71eca8a4a63349350ec"}}}
```

#### Deploy app2
Now we should be able to deploy app2 with a streamlined set of steps. All of the commands are provided below. The onboarding commands will be a one time step per application.

**Onboard app2**
```bash
# Create app two service account
export ns="retail"
export app="app2"
kubectl create sa ${app} -n ${ns}

# Create app2 role
export cluster_name="gke-useast1"
vault write auth/${cluster_name}/role/${ns}-${app} \
    bound_service_account_names=${app} \
    bound_service_account_namespaces=${ns} \
    policies=${cluster_name}-kv-read \
    period=120s

# Write a secret for app2
vault write kv/${ns}/${app} app=${app} username=demo-app2 password=test-app2
```

**Deploy app2**
```bash
# Create the app deployment yaml file with a set of substitutions
cat deployment-template.yaml | sed  -e s/"my-deployment"/"${app}-deployment"/ \
                                  -e s/"my-namespace"/${ns}/ \
                                  -e s/"my-app-name"/"basic-example-${app}"/g \
                                  -e s/"my-app-sa"/${app}/ \
                                  -e s/"secret-path"/"kv\/${ns}\/${app}"/ \
                                  -e s/"login-path"/"auth\/${cluster_name}\/login"/ \
                                  -e s/"my-role"/"${ns}-${app}"/ > deployment-$ns-$app.yaml 

kubectl create -f deployment-$ns-$app.yaml

# Ensure pod health checks are passing
kubectl get pods -n ${ns}

# Read logs
export pod_name=$(kubectl get pods -l app=basic-example-${app} -o jsonpath='{.items[0].metadata.name}' -n ${ns})
kubectl logs ${pod_name} -n ${ns}
```

With a successful deployment you should see output similar to below.
```bash
2021/01/04 16:33:13 ==> WARNING: Don't ever write secrets to logs.
2021/01/04 16:33:13 ==>          This is for demonstration only.
2021/01/04 16:33:13 s.q7F8o1aQL867awQzl2odsRBq
2021/01/04 16:33:13 secret kv/retail/app2 -> &{9f5e1259-5741-074c-599f-b1ff1e085e88  2764800 false map[app:app2 password:test-app2 username:demo-app2] [] <nil> <nil>}
2021/01/04 16:33:13 Starting renewal loop
2021/01/04 16:33:13 Successfully renewed: &api.RenewOutput{RenewedAt:time.Time{wall:0x6b5052f, ext:63745374793, loc:(*time.Location)(nil)}, Secret:(*api.Secret)(0xc00011a9c0)}
2021/01/04 16:33:13 secret kv/retail/app2 -> &{4ef5fb5d-2795-24f1-12cf-84e0d2eab8d9  2764800 false map[app:app2 password:test-app2 username:demo-app2] [] <nil> <nil>}
```

## Conclusion
In this demo we reviewed how to configure the Kubernetes Auth Method for applications to login and read secrets from Vault. Moreover, we saw how to use Vault Policy Path templates to create a reusable approach in onboarding applications to Vault at scale.
