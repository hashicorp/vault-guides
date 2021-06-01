## [DRAFT] Onboarding Applications to Vault using Terraform

This repo contains the source code for the onboarding approach described in this [blog post]()

### Provision demo Vault cluster and application using Docker compose
Please clone the repository as below and cd into the project directory:
```bash
git clone git@github.com:hashicorp/vault-guides.git
# checkout the onboarding-terraform branch (this will be removed after publishing to main branch)
git fetch
git checkout onboarding-terraform
cd vault-guides/operations/onboarding
```

Please `cd` into the docker-compose directory and run docker compose up as shown below. The remaining terminal snippets in this post will assume that you are in the project directory vault-guides/operations/onboarding.
```bash
cd docker-compose/ && docker compose up
```
Optionally, if you prefer using the tool make, there is a Makefile included in the project directory root. Run make info to see the available targets.

### Bootstrap Vault
```bash
# Assuming you are in the project root directory
cd docker-compose/scripts
00-init.sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=<token-from-init-script>
vault token lookup
```

**Admin Token (optional)**
You may prefer using an Admin token instead of Root, for example if using an existing cluster. If so, please create an admin token using the vault-admin.hcl policy file as shown below. This admin policy was based on the [Vault Policies learn guide]().
```bash
vault policy write learn-admin admin-policy.hcl
vault token create -policy=learn-admin
export VAULT_TOKEN=<token-from-above command>
vault token lookup
```

### Terraform configurations
We will use Terraform to create the following items: Application Entity, ACL Policy, Authentication Method Role and Secret Engine Role. In the file variables.tf, we have declared an `entities` variable that will hold a list of applications. To onboard more applications, we just need to append to this list . Please run the following commands to create all of the configurations easily.
```bash
# Please ensure you have VAULT_ADDR and Root or Admin VAULT_TOKEN set
cd terraform
terrafrom init
terraform plan
terraform apply --auto-approve
```

You should now be able to see the nginx container display a dynamic Postgres database password on http://localhost:8080. Also try accessing http://localhost:8080/kv to see nginx display example values stored in the key/value secrets engine.

### Onboarding another application
To onboard another application, simply add to the `entities` list in the file variables.tf. Then run `terraform plan` and `terraform apply` to create the necessary Vault configurations for this application. Since we are using policy templates, there is no need to create a new Policy. Verify from the Vault UI that there is a new entity called `app200`, with an alias to the AppRole Auth method.  A new Role ID and Secret ID has also been created which can be obtained from terraform output.