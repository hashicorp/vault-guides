# Vault HA Cluster with Integrated Storage (Raft)

These assets are provided to perform the tasks described in the following guides:

- [Vault HA with Raft Storage Backend](https://learn.hashicorp.com/vault/operations/raft-storage) guide uses the script in the [`local`](https://github.com/hashicorp/vault-guides/tree/master/operations/raft-storage/local) sub-folder
- [Vault HA with Raft Storage Backend on AWS](https://learn.hashicorp.com/vault/operations/raft-storage-aws) guide uses the Terraform files in the [`aws`](https://github.com/hashicorp/vault-guides/tree/master/operations/raft-storage/aws) sub-folder.

------

## Taking a Vault data snapshot

To take a snapshot of the Vault data, use the `raft snapshot save` command: `vault operator raft snapshot save <snapshot_name>`

**Example:**

```plaintext
$ vault operator raft snapshot save 2019-JULY-04.snapshot
```

Now, delete the secrets at `kv/apikey`:

```sh
$ vault kv metadata delete kv/apikey

# Verify that the data no longer exists:
$ vault kv get kv/apikey
No value found at kv/data/apikey
```

## Restoring data from a snapshot

To recover the lost data from a snapshot, use the `raft snapshot restore`
command:

```plaintext
vault operator raft snapshot restore <snapshot_name>
```

**Example:**

```plaintext
$ vault operator raft snapshot restore 2019-JULY-04.snapshot
```

Now, you the data should be recoverable at `kv/apikey`:

```plaintext
$ vault kv get kv/apikey

====== Metadata ======
Key              Value
---              -----
created_time     2019-07-02T05:50:39.038931Z
deletion_time    n/a
destroyed        false
version          2

======= Data =======
Key           Value
---           -----
expiration    365 days
webapp        ABB39KKPTWOR832JGNLS02
```


## Remove a cluster member

To join the HA cluster, you executed the `raft join <leader_addr>` command. To remove a node from the cluster, execute the `raft remove-peer` command: `vault operator raft remove-peer <node_id>`


**Example:**

```plaintext
$ vault operator raft remove-peer node3
Peer removed successfully!
```

Now, `node3` is removed from the HA cluster.

```plaintext
$ vault operator raft configuration -format=json | jq
```
