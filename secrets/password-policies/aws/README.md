# Password Policies

These assets are provided to perform the tasks described in the [User
Configurable Password Generation for Secret
Engines](https://learn.hashicorp.com/vault/secrets/password-policies) guide.

## Setup

1.  Set your AWS credentials as environment variables:

    ```plaintext
    $ export AWS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>"
    $ export AWS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>"
    ```

1.  Use the provided `terraform.tfvars.example` as a base to create a file named
    `terraform.tfvars` and specify the `key_name`. Be sure to set the correct
    [key
    pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
    name created in the AWS region that you are using.

    Example `terrafrom.tfvars`:

    ```shell
    # SSH key name to access EC2 instances (should already exist) on the AWS region
    key_name = "vault-test"

    # If you want to use a different AWS region
    aws_region = "us-west-1"
    availability_zones = "us-west-1a"
    ```

1.  Run Terraform commands to provision your cloud resources:

    ```plaintext
    $ terraform init

    $ terraform plan

    $ terraform apply -auto-approve
    ```

    The Terraform output will display the IP addresses of the provisioned Vault nodes.

    ```plaintext
    NOTE: While Terraform's work is done, the Vault server needs time to complete
          its own installation and configuration. Progress is reported within
          the log file `/var/log/tf-user-data.log` and reports 'Complete' when
          the instance is ready.

    vault-server (52.53.130.188) | internal: (10.0.101.21)
        - Initialized and unsealed.
        - The root token is stored in /home/ubuntu/root_key
        - The unseal key is stored in /home/ubuntu/unseal_keys

        $ ssh -l ubuntu 52.53.130.188 -i <path/to/key.pem>

    ```

## Generate RabbitMQ users

1.  SSH into the Vault server.

    ```sh
    $ ssh -l ubuntu 52.53.130.188 -i <path/to/key.pem>
    ```

1.  Generate a RabbitMQ user without password policy

    ```sh
    $ vault read rabbitmq-no-policy/creds/example
    Key                Value
    ---                -----
    lease_id           rabbitmq-no-policy/creds/example/pJXck84xmbZ7psIba3xb2hg4
    lease_duration     768h
    lease_renewable    true
    password           oorqjJo2XfcKZjWyW5ZMF4ytEp58yj8msplU
    username           root-48e7b8a5-8681-2eca-2dd5-a1ceddaf8765
    ```

1.  Create a RabbitMQ user with password policy

    ```sh
    $ vault read rabbitmq-with-policy/creds/example
    Key                Value
    ---                -----
    lease_id           rabbitmq-with-policy/creds/example/e2BTktqakyRwRNRJVV2h46a8
    lease_duration     768h
    lease_renewable    true
    password           0vCReyis*2GztJaefxCN
    username           root-b34542c6-2e88-f466-a3ca-3778c8bbf8b8
    ```

## Clean up

When you are done exploring, execute the `terraform destroy` command to terminate all AWS elements:

```plaintext
$ terraform destroy -auto-approve
```
