# Create a Vault HA cluster locally on your machine


### Setup an HA cluster

1. Execute the `/local-test/network.sh` script to add `127.0.0.2`, `127.0.0.3` and `127.0.0.4` loopback addresses.

    ```sh
    # Ensure that network.sh is executable
    $ chmod +x network.sh

    # Now, execute the network.sh script
    $ ./network.sh
    ```

    > 127.0.0.0/8 address block is assigned for use as the Internet host loopback
    address. ([RFC3330](https://tools.ietf.org/html/rfc3330))

1. At line 20 of the `raft-cluster-demo.sh` script, the `TEST_HOME` is set to
`$HOME/raft-test`. All the generated files and folders will be created under
this directory. If you wish to output elsewhere, be sure to modify this
variable.

    ```plaintext
    TEST_HOME=$HOME/raft-test
    ```

1. Execute the script to start four instances of Vault.

    ```sh
    # Make sure that the raft-cluster-demo.sh script is executable
    $ chmod +x raft-cluster-demo.sh

    # Execute the script
    $ ./raft-cluster-demo.sh
    ```

1. Examine the `vault_2` server configuration file (`config-vault2.hcl`):

    ```plaintext
    $ cat $TEST_HOME/config-vault2.hcl

    storage "raft" {
      path    = "$TEST_HOME/vault-raft/"
      node_id = "node2"
    }
    listener "tcp" {
      address = "127.0.0.2:8200"
      cluster_address = "127.0.0.2:8201"
      tls_disable = true
    }
    seal "transit" {
      address            = "http://127.0.0.1:8200"
      token              = "s.SsnAI6fJZKv1N1QMWP2rANDB"
      disable_renewal    = "false"

      // Key configuration
      key_name           = "unseal_key"
      mount_path         = "transit/"
    }
    disable_mlock = true
    cluster_addr = "http://127.0.0.2:8201"
    ```

    To use the integrated storage, the `storage` stanza must be set to **`raft`**. The `path` specifies the path where Vault data will be stored (`$TEST_HOME/vault-raft`). The `seal` stanza is configured to use [Transit
    Auto-unseal](/vault/operations/autounseal-transit) which is provided by `vault_1`. The configuration file for `vault_3` and `vault_4` are very similar.

1. Open a new terminal, and execute the `raft join` command to add `vault_3` to the HA cluster.

    ```plaintext
    $ vault operator raft join http://127.0.0.2:8200
    ```

1. Similarly, open another terminal and add `vault_4` to the HA cluster:

    ```plaintext
    $ export VAULT_ADDR=http://127.0.0.4:8200

    $ vault operator raft join http://127.0.0.2:8200
    ```

1. Execute the `raft configuration` command to list the cluster members:

    ```plaintext
    $ vault operator raft configuration -format=json | jq
    ```

Now, you have a cluster with 3 nodes.



# Clean up

Execute the following to terminate all Vault processes:

```plaintext
$ pkill vault
```
