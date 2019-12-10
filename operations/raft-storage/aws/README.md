# Create a Vault HA cluster on AWS using Terraform

1.  Set your AWS credentials as environment variables:

    ```plaintext
    $ export AWS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>"
    $ export AWS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>"
    ```

1.  Use the provided `terraform.tfvars.example` as a base to create a file named `terraform.tfvars` and specify the `key_name`. Be sure to set the correct [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) name created in the AWS region that you are using.

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
    vault_1 (13.56.238.70)
      - Initialized and unsealed.
      - The root token creates a transit key that enables the other Vaults to auto-unseal.
      - Does not join the High-Availability (HA) cluster.

      Local: VAULT_ADDR=http://13.56.238.70:8200 vault
      Web:   open http://13.56.238.70:8200/ui/
      SSH:   ssh -l ubuntu 13.56.238.70 -i <path/to/key.pem>

    vault_2 (13.56.210.19)
      - Initialized and unsealed.
      - The root token and recovery key is stored in /tmp/key.json.
      - K/V-V2 secret engine enabled and secret stored.
      - Leader of HA cluster

      Local: VAULT_ADDR=http://13.56.210.19:8200 vault
      Web:   open http://13.56.210.19:8200/ui/
      SSH:   ssh -l ubuntu 13.56.210.19 -i <path/to/key.pem>

      Root Token:
        ssh -l ubuntu -i <path/to/key.pem> 13.56.210.19 'cat /tmp/key.json | jq -r ".root_token"'
      Recovery Key:
        ssh -l ubuntu -i <path/to/key.pem> 13.56.210.19 'cat /tmp/key.json | jq -r ".recovery_keys_b64[0]"'

    vault_3 (54.183.135.252)
      - Started
      - You will join it to the HA cluster.

      Local: VAULT_ADDR=http://54.183.135.252:8200 vault
      Web:   open http://54.183.135.252:8200/ui/
      SSH:   ssh -l ubuntu 54.183.135.252 -i <path/to/key.pem>

    vault_4 (13.57.238.164)
      - Started
      - You will join it to the HA cluster.

      Local: VAULT_ADDR=http://13.57.238.164:8200 vault
      Web:   open http://13.57.238.164:8200/ui/
      SSH:   ssh -l ubuntu 13.57.238.164 -i <path/to/key.pem>
    ```

1.  SSH into **vault_2**.

    ```sh
    ssh -l ubuntu 13.56.210.19 -i <path/to/key.pem>
    ```

1.  Check the current number of servers in the HA Cluster.

    ```plaintext
    $ VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token") vault operator raft configuration -format=json | jq  ".data.config.servers[]"
    {
      "address": "10.0.101.226:8201",
      "leader": true,
      "node_id": "vault_2",
      "protocol_version": "3",
      "voter": true
    }
    ```

1.  Open a new terminal, SSH into **vault_3**.

    ```plaintext
    $ ssh -l ubuntu 54.183.135.252 -i <path/to/key.pem>
    ```

1.  Join **vault_3** to the HA cluster started by **vault_2**.

    ```plaintext
    $ vault operator raft join http://13.56.210.19:8200
    ```

1.  Open a new terminal and SSH into **vault_4**

    ```plaintext
    $ ssh -l ubuntu 13.57.238.164 -i <path/to/key.pem>
    ```

1.  Join **vault_4** to the HA cluster started by **vault_2**.

    ```plaintext
    $ vault operator raft join http://13.56.210.19:8200
    ```

1.  Return to the original terminal and check the current number of servers in
    the HA Cluster.

    ```plaintext
    $ VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token") vault operator raft configuration -format=json | jq  ".data.config.servers[]"
    {
      "address": "10.0.101.226:8201",
      "leader": true,
      "node_id": "vault_2",
      "protocol_version": "3",
      "voter": true
    }
    {
      "address": "10.0.101.140:8201",
      "leader": false,
      "node_id": "vault_3",
      "protocol_version": "3",
      "voter": true
    }
    {
      "address": "10.0.101.204:8201",
      "leader": false,
      "node_id": "vault_4",
      "protocol_version": "3",
      "voter": true
    }
    ```

    You should see **vault_2**, **vault_3**, and **vault_4** in the cluster.

# Clean up the cloud resources

When you are done exploring, execute the `terraform destroy` command to terminal all AWS elements:

```plaintext
$ terraform destroy -auto-approve
```
