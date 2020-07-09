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
      - SSH secrets engine ENABLED
      - User authentication enabled
          * user: learn_vault
          * password: hashicorp

      $ ssh -l ubuntu 52.53.193.90 -i <path/to/key.pem>

      # Root token:
      $ ssh -l ubuntu 52.53.193.90 -i <path/to/key.pem> "cat ~/root_token"

    remote-host (13.56.247.45) | internal: (10.0.101.22)
      - Vault SSH helper installed
      - PAM configured
      - SSHD configured

      $ ssh -l ubuntu 13.56.247.45 -i <path/to/key.pem>
    ```

## Generate OTP

1.  SSH into the Vault server.

    ```sh
    $ ssh -l ubuntu 52.53.193.90 -i <path/to/key.pem>
    ```


1.  Login to Vault using the `userpass` method with user `learn_vault` and password `hashicorp`.

    ```sh
    $ vault login -method=userpass username=learn_vault password=hashicorp
    ```

1.  Generate an OTP

    ```sh
    $ vault write ssh/creds/otp_key_role ip=10.0.101.22
    Key                Value
    ---                -----
    lease_id           ssh/creds/otp_key_role/xGu0y8QtatlFTm3sc5BX4fCD
    lease_duration     768h
    lease_renewable    false
    ip                 10.0.101.22
    key                35e507cf-d589-6fbf-e5b6-39cd7531dfe6
    key_type           otp
    port               22
    username           ubuntu
    ```
1.  SSH into the remote-host with the OTP

    ```sh
    $ ssh ubuntu@10.0.101.22
    Password:
    ```

    > **NOTE:** If you copy-and-paste the password allow for some time for the tty to complete the paste operation.

## Clean up

When you are done exploring, execute the `terraform destroy` command to terminal all AWS elements:

```plaintext
$ terraform destroy -auto-approve
```
