# Vault Agent Caching

These assets are provided to provision AWS resources to perform the steps described in the [Vault Agent Caching](https://learn.hashicorp.com/vault/) guide.

---

**NOTE:** The example Terraform in this repository is created for the demo purpose, and not suitable for production use. For production deployment, refer the following examples:

- [operations/provision-vault](https://github.com/hashicorp/vault-guides/tree/master/operations/provision-vault)
- [Terraform Module Registry](https://registry.terraform.io/modules/hashicorp/vault)


## Demo Steps

1. Set this location as your working directory

1. Set your AWS credentials as environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

1. Set the Terraform variable values in a file named `terraform.tfvars` (use `terraform.tfvars.example` as a base)

    ```shell
    # SSH key name to access EC2 instances (should already exist)
    key_name = "vault-test"

    # All resources will be tagged with this
    environment_name = "va-demo"

    # If you want to use a different AWS region
    aws_region = "us-west-1"
    availability_zones = "us-west-1a"
    ```

1. Run Terraform:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply -auto-approve
    ```

### Vault Server

1. SSH into the Vault **server** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_server>`

1. On the **server** instance, run the following commands:

    ```shell
    # Initialize Vault
    $ vault operator init > key.txt

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')

    # Check the Vault server status
    $ vault status
    ```

1. Run aws_auth.sh script to enable and configure AWS auth method

    ```plaintext
    $ ./aws_auth.sh
    ```

1. Also, run auth_secret.sh script to enable and configure AWS secrets engine

    ```plaintext
    $ ./aws_secrets.sh
    ```

### Vault Client

1. SSH into the Vault **client** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_client>`

1. Ensure that VAULT_ADDR has been set: `echo $VAULT_ADDR`

1. On the **client** instance, examine the Vault Agent file, `vault-agent.hcl`:

    ```shell
    $ cat vault-agent.hcl

    exit_after_auth = false
    pid_file = "./pidfile"

    cache {
       use_auto_auth_token = true
       listener "tcp" {
          address = "127.0.0.1:8300"
          tls_disable = true
       }
    }

    auto_auth {
       method "aws" {
           mount_path = "auth/aws"
           config = {
               type = "iam"
               role = "app-role"
           }
       }

       sink "file" {
           config = {
               path = "/home/ubuntu/vault-token-via-agent"
           }
       }
    }
    ```

    **NOTE:** Notice the `cache` block. The TCP listener is configured to listen to port 8200 on the client host.

1. Run Vault Agent:

    ```plaintext
    $ vault agent -config=/home/ubuntu/auto-auth-conf.hcl -log-level=debug
    ```

1. Open another client host SSH terminal and verify that a token has been acquired:

    ```plaintext
    $ more vault-token-via-agent
    ```

1. Verify that you can get an AWS credentials:

    ```plaintext
    $ curl -s --header "X-Vault-Token: $(cat /home/ubuntu/vault-token-via-agent)" \
            http://127.0.0.1:8300/v1/aws/creds/readonly | jq
    ```

    On the terminal where Vault Agent is running, the log should indicate that the request was properly routed to the Vault server and the retrieved lease is cashed.

    ```plaintext
    ...
    [INFO]  cache: received request: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: forwarding request: path=/v1/aws/creds/readonly method=GET
    [INFO]  cache.apiproxy: forwarding request: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: processing lease response: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: pass-through lease response; token not managed by agent: path=/v1/aws/creds/readonly method=GET
    ```

1. Clear all cache:

    ```plaintext
    curl --request POST --data '{ "type": "all" }' http://127.0.0.1:8300/v1/agent/cache-clear
    ```

    ```plaintext
    [DEBUG] cache.leasecache: received cache-clear request: type=all namespace= value=
    [DEBUG] cache.leasecache: cancelling base context
    [DEBUG] cache.leasecache: successfully cleared matching cache entries
    ```

1. Clean up

    ```plaintext
    $ terraform destroy -force
    $ rm -rf .terraform terraform.tfstate* private.key
    ```
