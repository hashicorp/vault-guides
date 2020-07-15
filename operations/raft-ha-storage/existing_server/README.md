# Create a Vault cluster locally on your machine

1. Set the `cluster.sh` file to executable:

    ```shell
    $ chmod +x cluster.sh
    ```

1. Setup a Vault server which uses filesystem storage backend.

    ```shell
    $ ./cluster.sh setup vault_1
    ```

1. Review the server configuration file, `config-vault_1.hcl`.

    ```shell
    $ cat config-vault_1.hcl
    ```

1. The server status shows that `HA Enabled` is `false`.

    ```shell
    $ VAULT_ADDR=http://127.0.0.1:8210 vault status

    Key             Value
    ---             -----
    Seal Type       shamir
    Initialized     true
    Sealed          false
    Total Shares    1
    Threshold       1
    Version         1.5.0
    Cluster Name    vault-cluster-f467afe0
    Cluster ID      8380262f-64a4-6eb5-716a-4a1fef8ce153
    HA Enabled      false
    ```

1. Stop `vault_1` before update its configuration.

    ```shell
    $ ./cluster.sh stop vault_1
    ```

1. Upate `vault_1` to define its `ha_storage`.

    ```shell
    $ ./cluster.sh update
    ```

1. You can now add additional nodes, `vault_2`.

    ```shell
    $ ./cluster.sh setup vault_2
    ```

1. Add `vault_3` to the raft cluster.

    ```shell
    $ ./cluster.sh setup vault_3
    ```

## Clean up

Execute the script to clean up the environment.

```shell
$ ./cluster.sh clean
```
