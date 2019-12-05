# Vault Agent with AWS

These assets are provided to provision AWS resources to perform the steps described in the [Vault Agent with AWS](https://learn.hashicorp.com/vault/identity-access-management/vault-agent-aws) guide.

---

**NOTE:** The example Terraform in this repository is created for the demo purpose, and not suitable for production use. For production deployment, refer the following examples:

- [operations/provision-vault](https://github.com/hashicorp/vault-guides/tree/master/operations/provision-vault)
- [Terraform Module Registry](https://registry.terraform.io/modules/hashicorp/vault/aws/0.10.3)


## Demo Steps

1. Set this location as your working directory

1. Set your AWS credentials as environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

1. Set the Terraform variable values in a file named `terraform.tfvars` (use `terraform.tfvars.example` as a base)

    ```shell
    # SSH key name to access EC2 instances (should already exist)
    key_name = "vault-test"

    # All resources will be tagged with this
    environment_name = "va-demo"
    ```

1. Run Terraform:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply -auto-approve
    ```

1. SSH into the Vault **server** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_server>`

1. On the **server** instance, run the following commands:

    ```shell
    # Initialize Vault
    $ vault operator init -stored-shares=1 -recovery-shares=1 \
            -recovery-threshold=1 -key-shares=1 -key-threshold=1 > key.txt

    # Vault should've been initialized and unsealed
    $ vault status

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')

    # Create a policy file
    $ tee myapp.hcl <<EOF
    path "secret/myapp/*" {
        capabilities = ["read", "list"]
    }
    EOF

    # Run the setup script
    $ ./aws_auth.sh
    ```

1. SSH into the Vault **client** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_client>`

1. On the **client** instance, run the following commands:

    ```shell
    # Create the Vault Agent configuration file
    $ tee /home/ubuntu/auto-auth-conf.hcl <<EOF
    exit_after_auth = true
    pid_file = "./pidfile"

    auto_auth {
       method "aws" {
           mount_path = "auth/aws"
           config = {
               type = "iam"
               role = "dev-role-iam"
           }
       }

       sink "file" {
           config = {
               path = "/home/ubuntu/vault-token-via-agent"
           }
       }
    }
    EOF


    # Run Vault Agent
    $ vault agent -config=/home/ubuntu/auto-auth-conf.hcl -log-level=debug
    ```

1. Verify that the Auto-Auth works:

    ```shell
    # Verify that a token was written to the configured sink location
    $ more vault-token-via-agent

    # Test to make sure that the token has appropriate policy attached
    $ curl --header "X-Vault-Token: $(cat /home/ubuntu/vault-token-via-agent)" \
            $VAULT_ADDR/v1/secret/myapp/config | jq
    ```

1. To demonstrate the Auto-Auth with response-wrapped token, execute the following command on the **client**.

    ```shell
    # Add 'wrap_ttl' in the sink block
    $ tee /home/ubuntu/auto-auth-conf.hcl <<EOF
    exit_after_auth = true
    pid_file = "./pidfile"

    auto_auth {
        method "aws" {
            mount_path = "auth/aws"
            config = {
                type = "iam"
                role = "dev-role-iam"
            }
        }

        sink "file" {
            wrap_ttl = "5m"
            config = {
                path = "/home/ubuntu/vault-token-via-agent"
            }
        }
    }
    EOF

    # Re-run Vault Agent with updated configuration file
    $ vault agent -config=/home/ubuntu/auto-auth-conf.hcl -log-level=debug

    # Unwrap the wrapped token and set it as VAULT_TOKEN environment variable
    $ export VAULT_TOKEN=$(vault unwrap -field=token $(jq -r '.token' /home/ubuntu/vault-token-via-agent))

    # Test to make sure that the token has appropriate policy attached
    $ curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/myapp/config | jq
    ```

1. Clean up

    ```plaintext
    $ terraform destroy -force
    $ rm -rf .terraform terraform.tfstate* private.key
    ```
