# SSH Secrets Engine: One-Time SSH Password

These assets are provided to perform the tasks described in the [SSH Secrets Engine: One-Time SSH Password](https://learn.hashicorp.com/vault/security/sm-ssh-otp) guide.

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
    vault-server (52.53.193.90) | internal: (10.0.101.21)
      - Initialized and unsealed.
      - The root token and recovery key is stored in /tmp/key.json.

      $ ssh -l ubuntu 52.53.193.90 -i <path/to/key.pem>

    remote-host (13.56.247.45) | internal: (10.0.101.22)

      $ ssh -l ubuntu 13.56.247.45 -i <path/to/key.pem>
    ```

## Clean up

When you are done exploring, execute the `terraform destroy` command to terminal all AWS elements:

```plaintext
$ terraform destroy -auto-approve
```
