# Create a cluster with ha_storage

1. Set the `cluster.sh` file to executable.

    ```shell
    $ chmod +x cluster.sh
    ```

1. Create the configuration for each Vault.

    ```shell
    $ ./cluster.sh create config
    ```

1. Review the server configuration file for `vault_1`.

    ```shell
    $ cat config-vault_1.hcl
    ```

    The `storage` stanza is configured to use filesystem as the storage backend
    which does not support HA. In addition, to support HA, the `ha_storage` stanza
    is configured. As of Vault 1.5, integrated storage can be used as a HA
    storage.

1. Setup `vault_1`.

    ```shell
    $ ./cluster.sh setup vault_1
    ```

    The script (1) terminates all Vault server instances that are running locally,
    (2) start a Vault server, (3) initialize and unseal the server, (4) enable
    `kv-v2` secrets engine at `kv`, and (5) create some secrets at the
    `kv/apikey`.

1.  Setup `vault_2`.

    ```shell
    $ ./cluster.sh setup vault_2
    ```

1. Finally, setup `vault_3`.

    ```shell
    $ ./cluster.sh setup vault_3
    ```
