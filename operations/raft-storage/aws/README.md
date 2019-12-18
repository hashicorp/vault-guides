# Create a Vault HA cluster on AWS using Terraform

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
    vault_1 (13.56.78.64)  | internal: (10.0.101.21)
      - Initialized and unsealed.
      - The root token creates a transit key that enables the other Vaults to auto-unseal.
      - Does not join the High-Availability (HA) cluster.

    vault_2 (13.56.255.200) | internal: (10.0.101.22)
      - Initialized and unsealed.
      - The root token and recovery key is stored in /tmp/key.json.
      - K/V-V2 secret engine enabled and secret stored.
      - Leader of HA cluster

      $ ssh -l ubuntu 13.56.255.200 -i <path/to/key.pem>

      # Root token:
      $ ssh -l ubuntu 13.56.255.200 -i <path/to/key.pem> "cat ~/root_token"
      # Recovery key:
      $ ssh -l ubuntu 13.56.255.200 -i <path/to/key.pem> "cat ~/recovery_key"

    vault_3 (54.183.62.59) | internal: (10.0.101.23)
      - Started
      - You will join it to cluster started by vault_2

      $ ssh -l ubuntu 54.183.62.59 -i <path/to/key.pem>

    vault_4 (13.57.235.28) | internal: (10.0.101.24)
      - Started
      - You will join it to cluster started by vault_2

      $ ssh -l ubuntu 13.57.235.28 -i <path/to/key.pem>
    ```

1.  SSH into **vault_2**.

    ```sh
    ssh -l ubuntu 13.56.255.200 -i <path/to/key.pem>
    ```

1.  Check the current number of servers in the HA Cluster.

    ```plaintext
    $ VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token") vault operator raft configuration -format=json | jq  ".data.config.servers[]"
    {
      "address": "10.0.101.22:8201",
      "leader": true,
      "node_id": "vault_2",
      "protocol_version": "3",
      "voter": true
    }
    ```

1.  Open a new terminal, SSH into **vault_3**.

    ```plaintext
    $ ssh -l ubuntu 54.183.62.59 -i <path/to/key.pem>
    ```

1.  Join **vault_3** to the HA cluster started by **vault_2**.

    ```plaintext
    $ vault operator raft join http://vault_2:8200
    ```

1.  Open a new terminal and SSH into **vault_4**

    ```plaintext
    $ ssh -l ubuntu 13.57.235.28 -i <path/to/key.pem>
    ```

1.  Join **vault_4** to the HA cluster started by **vault_2**.

    ```plaintext
    $ vault operator raft join http://vault_2:8200
    ```

1.  Return to the original terminal and check the current number of servers in
    the HA Cluster.

    ```plaintext
    $ VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token") vault operator raft configuration -format=json | jq  ".data.config.servers[]"
    {
      "address": "10.0.101.22:8201",
      "leader": true,
      "node_id": "vault_2",
      "protocol_version": "3",
      "voter": true
    }
    {
      "address": "10.0.101.23:8201",
      "leader": false,
      "node_id": "vault_3",
      "protocol_version": "3",
      "voter": true
    }
    {
      "address": "10.0.101.24:8201",
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
