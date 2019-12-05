# Vault Agent with AWS

These assets are provided to provision AWS resources to perform the steps described in the [Vault Agent Template](https://learn.hashicorp.com/vault/identity-access-management/agent-templates) guide.

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

    # A tag - All resources will be tagged with this string
    environment_name = "va-demo"
    ```

    > If you don't have an EC2 Key Pairs, refer to the [AWS doc](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) and create one.

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
    # Initialize Vault and store the output in key.txt
    $ vault operator init > key.txt

    # Vault should've been initialized and auto-unsealed
    $ vault status

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')

    # Run the aws_auth.sh script to setup the server
    #   - Enables kv-v2 at secret/
    #   - Stores secrets at secret/customers/acme
    #   - Enables aws auth method
    #   - Configures the aws auth method and create app-role
    $ ./aws_auth.sh
    ```

1. SSH into the Vault **client** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_client>`

1. On the **client** instance, run Vault Agent:

    ```shell
    # Examine the agent configuration
    $ cat vault-agent.hcl

    # Run Vault Agent
    $ vault agent -config=/home/ubuntu/vault-agent.hcl -log-level=debug
    ```

## Verification

Open another SSH terminal connected to the **client** instance. Verify that the Auto-Auth worked:

```shell
# Verify that a token was written to the configured sink location
$ more /home/ubuntu/vault-token-via-agent

# You should find customer.txt file generated
$ cat customer.txt
```

Based on the `customer.tmpl` file, Vault Agent executed Consul-Template, read the secrets at `secret/data/customers/acme` and populated the `customer.txt` file.

**Question:** What happens if you update the secrets at `secret/data/customers/acme`?

**Answer:** Try it for yourself.

1. On the **server** instance, update the `contact_email` to `jenn@acme.com`:

    ```shell
    $ vault kv patch secret/customers/acme contact_email="jenn@acme.com"

    # Verify that the data was successfully updated
    $ vault kv get secret/customers/acme
    ```

1. Return to the **client** instance SSH session where the Vault Agent is running. Wait for a few minutes (~5 minutes). The agent pulls the secrets again.


## Clean up

```plaintext
$ terraform destroy -auto-approve
$ rm -rf .terraform terraform.tfstate* private.key
```
