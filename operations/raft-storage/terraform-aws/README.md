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


1.  There are three Vault server nodes provisioned by Terraform. The Terraform output displays three server node IP addresses as well as private IP addresses.

    **Example:**

    ```plaintext
    Server node IPs (public):  54.215.244.175, 54.193.26.177, 54.153.90.97
    Server node IPs (private): 10.0.101.53, 10.0.101.15, 10.0.101.73

    For example:
       ssh -i vault-test.pem ubuntu@54.215.244.175
    ```

    SSH into one of the three server nodes: `ssh -i <path_to_key> ubuntu@<public_ip>`

    ```plaintext
    $ ssh -i vault-test.pem ubuntu@54.215.244.175
    ```

1.  Examine the server configuration file, `/etc/vault.d/vault.hcl`.

    ```plaintext
    $ sudo cat /etc/vault.d/vault.hcl
    ```

    To use the integrated storage, the `storage` stanza must be set to **`raft`**. The `path` specifies the path where Vault data will be stored (`/vault/storage1`). The `seal` stanza is configured to use [Transit Auto-unseal](/vault/operations/autounseal-transit) which is provided by the _Auto-unseal Provider_ instance.

    Optionally, you can review the Vault service `systemd` file which is located at `/etc/systemd/system/vault.service`.

1.  Start the Vault server:

    ```sh
    # Start the Vault service
    $ sudo systemctl start vault

    # Check the service log
    $ sudo journalctl --no-page -u vault
    ```

1.  Run the `vault operator init` command to initialize the Vault server, and save the generated unseal keys and initial root token.

    ```plaintext
    $ vault operator init > key.txt
    ```

    Vault is now initialized and auto-unsealed.

1.  Log into Vault using the generated initial root token which is stored in the `key.txt` file.

    ```plaintext
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')
    ```

1.  Enable the Key/Value v2 secrets engine and create some test data.

    ```sh
    # Enable k/v v2 at 'kv' path
    $ vault secrets enable -path=kv kv-v2

    # Create some test data, kv/apikey
    $ vault kv put kv/apikey webapp=ABB39KKPTWOR832JGNLS02
    ```

1.  Check the integrated storage for this server.

    ```plaintext
    $ vault operator raft configuration -format=json | jq
    ```

1.  Open a new terminal and SSH into another Vault server node.

    **Example:**

    ```plaintext
    $ ssh -i vault-test.pem ubuntu@54.193.26.177
    ```

1.  Edit the server configuration file (`/etc/vault.d/vault.hcl`) to modify the `storage` stanza.

    ```plaintext
    $ sudo vi /etc/vault.d/vault.hcl
    ```

    In the `storage` stanza, modify `/vault/storage1` to **`/vault/storage2`**. Also, modify `node1` to **`node2`**:

    ```plaintext
    storage "raft" {
      path    = "/vault/storage2"
      node_id = "node2"
    }
    ...
    ```

1.  Now, start the Vault service.

    ```plaintext
    $ sudo systemctl start vault
    ```

1.  Execute the `raft join` command to add the second node to the HA cluster. Since you already initialized and unsealed a node, pass its API address to join the HA cluster: `vault operator raft join <leader_node_API_addr>`

    For example, if the public IP address of `node1` is `54.215.244.175`,

    ```plaintext
    $ vault operator raft join http://54.215.244.175:8200
    ```

1.  Similarly, open another terminal and SSH into the third node:

    **Example:**

    ```plaintext
    $ ssh -i vault-test.pem ubuntu@54.153.90.97
    ```

1.  Edit the server configuration file (`/etc/vault.d/vault.hcl`) to modify the `storage` stanza.

    ```plaintext
    $ sudo vi /etc/vault.d/vault.hcl
    ```

    In the `storage` stanza, modify `/vault/storage1` to **`/vault/storage3`**. Also, modify `node1` to **`node3`**:

    ```plaintext
    storage "raft" {
      path    = "/vault/storage3"
      node_id = "node3"
    }
    ...
    ```

1.  Now, start the Vault service.

    ```plaintext
    $ sudo systemctl start vault
    ```

1.  Execute the `raft join` command to add the third node to the HA cluster. Again, the target node to join is the first server you initialized and unsealed.

    **Example:**

    ```plaintext
    $ vault operator raft join http://54.215.244.175:8200
    ```

1.  Execute the `raft configuration` command again to see the cluster members.

    ```plaintext
    $ vault operator raft configuration -format=json | jq
    ```

    You should see all three nodes in the HA cluster.



# Clean up the cloud resources

When you are done exploring, execute the `terraform destroy` command to terminal all AWS elements:

```plaintext
$ terraform destroy -auto-approve
```
