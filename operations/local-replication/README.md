# Local replication
Vault is a lightweight binary that runs as a single process. This allows multiple Vault processes to easily run on a single machine, which is useful for testing/validation of Vault capabilities, as well as for development purposes. In this example, we will run three Vault processes to validate Vault replication capabilities and operations.

The first Vault will be the primary, both for performance and for DR replications. The second Vault will be the secondary for performance, while the third will be the secondary for DR. 

More information on performance and DR replication can be found at the following links:  
https://www.vaultproject.io/docs/enterprise/replication/index.html   
https://learn.hashicorp.com/vault/operations/ops-disaster-recovery  
https://learn.hashicorp.com/vault/operations/ops-replication  

Note: Requires Vault Enterprise binary in your local OS flavor. Instructions assume bash and common shell operations.

# Bash alias setup

Store the following in your .bash_profile/.bashrc or whatever


```
alias vrd='VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8200 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8200 -dev-ha -dev-transactional'
alias vrd2="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8202 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8202 -dev-ha -dev-transactional"
alias vrd3="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8204 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8204 -dev-ha -dev-transactional"


vault2 () {
  VAULT_ADDR=http://127.0.0.1:8202 vault $@
}

vault3 () {
  VAULT_ADDR=http://127.0.0.1:8204 vault $@
}

vault4 () {
  VAULT_ADDR=http://127.0.0.1:8206 vault $@
}

```

Three separate Vault processes will run in development mode in the foreground, and there is a significant amount of output. It is advisable to adjust your terminal buffer to allow you to scroll to view the initial execution and capture the unseal key.

Execute the following in three separate terminals
```
vrd
vrd2
vrd3
```

Make sure you write down the unseal key of "vrd" for DR setup command (or as noted above, have the ability to scroll back and copy/paste)

Vault UI links:  
http://127.0.0.1:8200  
http://127.0.0.1:8202  
http://127.0.0.1:8204  

Ensure you have the following environment variables configured

```sh
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_SKIP_VERIFY=true
```

Model is as follows
```
+---------------------------------+                    +------------------------------------+
| vault port:8200                 |                    | vault2 port: 8202                  |
| Performance primary replication |    +----------->   | Performance secondary replication  |
| DR primary replication          |                    | (vault -> vault2)                  |
|                                 |                    |                                    |
+---------------------------------+                    +------------------------------------+

               +
               |
               v

+---------------------------------+
| vault3 port:8204                |
| DR secondary replication        |
| (vault -> vault3)               |
|                                 |
+---------------------------------+
```

Next we'll create some users, policies and secrets on the primary cluster.
This information will be validated on the replicated clusters as part of this exercise.

```sh
vault login root
vault auth enable userpass
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write vault-admin -

vault write auth/userpass/users/vault password=vault policies=vault-admin
```

Create a normal user and write some data
```sh
vault login root
vault write auth/userpass/users/drtest password=drtest policies=user

echo '
path "supersecret/*" {
  capabilities = ["list", "read"]
}' | vault policy write user -
vault secrets enable -path=supersecret generic
vault kv put supersecret/drtest username=harold password=baines
```


Setup performance replication (vault->vault2)
```sh
vault login root
vault write -f sys/replication/performance/primary/enable
sleep 5
PRIMARY_PERF_TOKEN=$(vault write -format=json sys/replication/performance/primary/secondary-token id=vault2 \
  | jq --raw-output '.wrap_info .token' )
vault2 login root
vault2 write sys/replication/performance/secondary/enable token=${PRIMARY_PERF_TOKEN}
```

Validation of performance replication on the primary cluster (vault)
```sh
curl -s http://127.0.0.1:8200/v1/sys/replication/status | jq
{
  "request_id": "740f4ffe-dad0-13f1-21d9-099da6eb0e69",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "dr": {
      "mode": "disabled"
    },
    "performance": {
      "cluster_id": "07db81d4-b2b5-e75b-6db0-5ebb74ffcffd",
      "known_secondaries": [
        "vault2"
      ],
      "last_reindex_epoch": "0",
      "last_wal": 52,
      "merkle_root": "4ad2747ab839d297167e8dddf118bfa0fde77b82",
      "mode": "primary",
      "primary_cluster_addr": "",
      "state": "running"
    }
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```
Validation of performance replicaton on the secondary cluster (vault2)

```sh
curl -s http://127.0.0.1:8202/v1/sys/replication/status | jq
{
  "request_id": "20b0a6c1-006b-ab5c-5eba-21766191ae38",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "dr": {
      "mode": "disabled"
    },
    "performance": {
      "cluster_id": "07db81d4-b2b5-e75b-6db0-5ebb74ffcffd",
      "known_primary_cluster_addrs": [
        "https://127.0.0.1:8201"
      ],
      "last_reindex_epoch": "1575783871",
      "last_remote_wal": 0,
      "merkle_root": "4ad2747ab839d297167e8dddf118bfa0fde77b82",
      "mode": "secondary",
      "primary_cluster_addr": "https://127.0.0.1:8201",
      "secondary_id": "vault2",
      "state": "stream-wals"
    }
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```
At this point, you can validate that the user, policies and secrets have been replicated to the performance secondary cluster
```
vault2 login root
vault2 kv get supersecret/drtest
```
The secret read should return the following:
```sh
====== Data ======
Key         Value
---         -----
password    baines
username    harold
```


Now setup DR replication (vault -> vault3)
```sh
vault login root
vault write -f /sys/replication/dr/primary/enable
sleep 5
PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id="vault3" | jq --raw-output '.wrap_info .token' )
vault3 login root
vault3 write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}
```

Validation of disaster replication on the primary using the CLI (vault), and jq just to make the output a bit more legible
```sh
vault read -format=json sys/replication/status | jq
{
  "request_id": "5f7cbff4-71e9-fcc1-a78f-4f95a2241354",
  "lease_id": "",
  "lease_duration": 0,
  "renewable": false,
  "data": {
    "dr": {
      "cluster_id": "e483f3aa-dab6-9d33-a503-5fde5b76dee5",
      "known_secondaries": [
        "vault3"
      ],
      "last_reindex_epoch": "0",
      "last_wal": 70,
      "merkle_root": "6dd7cf70f0bd610707ded7cd9d563503e442b812",
      "mode": "primary",
      "primary_cluster_addr": "",
      "state": "running"
    },
    "performance": {
      "cluster_id": "325262f9-5ea3-56c1-bd4f-199f4cfda23a",
      "known_secondaries": [
        "vault2"
      ],
      "last_reindex_epoch": "0",
      "last_wal": 70,
      "merkle_root": "0036939b8989e3ede453cbae61a4a83d1d330e34",
      "mode": "primary",
      "primary_cluster_addr": "",
      "state": "running"
    }
  },
  "warnings": null
}
```

Validation of disaster recovery replication on the DR secondary using API (vault3)
```sh
curl -s http://127.0.0.1:8204/v1/sys/replication/status | jq
{
  "request_id": "0b352c1a-3407-a2a3-f6e9-7624d29f0065",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "dr": {
      "cluster_id": "2f665cf6-52f4-f83a-4de0-d873996ba7f4",
      "known_primary_cluster_addrs": [
        "https://127.0.0.1:8201"
      ],
      "last_reindex_epoch": "1575783991",
      "last_remote_wal": 68,
      "merkle_root": "7ae41b10dbe8c3838411e23273417c98c91b25ea",
      "mode": "secondary",
      "primary_cluster_addr": "https://127.0.0.1:8201",
      "secondary_id": "vault3",
      "state": "stream-wals"
    },
    "performance": {
      "mode": "disabled"
    }
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

To promote a DR secondary to a primary cluster, a DR operation token must be generated.

First we will check to see if the 'generate operation token' process has not been initiated. These operations are completed on the DR secondary.
```sh
curl -s http://127.0.0.1:8204/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq
{
  "nonce": "",
  "started": false,
  "progress": 0,
  "required": 1,
  "complete": false,
  "encoded_token": "",
  "encoded_root_token": "",
  "pgp_fingerprint": "",
  "otp": "",
  "otp_length": 26
}
```
Next we will generate a one time password (otp) 
```sh
DR_OTP=$(vault3 operator generate-root -dr-token -generate-otp)
```
Next we will initiate the DR token generation process by creating a nonce
```sh
NONCE=$(vault3 operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
```

Next, validate the process has started
```sh
curl -s http://127.0.0.1:8204/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq
{
  "nonce": "75305075-1005-b02a-7f52-eddec2ed1d97",
  "started": true,
  "progress": 0,
  "required": 1,
  "complete": false,
  "encoded_token": "",
  "encoded_root_token": "",
  "pgp_fingerprint": "",
  "otp": "",
  "otp_length": 26
}
```

The DR Operation token requires the unseal key from the DR primary (vault) as well as the nonce created in the prior execution.

Note that production clusters would normally require several executions to correlate with the Shamir sharing threshold number of keys, and the nonce must be distributed to each of the individual key holders.

Scroll back through the startup from vrd (the first Vault process - `vault`) and copy and paste the key similar to the following
```sh
PRIMARY_UNSEAL_KEY="YOUR_UNSEAL_KEY_GOES_HERE___DO_NOT_COPY_AND_PASTE_THIS_LINE"
```

Initiate DR token generation, provide unseal keys (1 unseal key in our example)  
```sh
ENCODED_TOKEN=$(vault3 operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )
```

An example using the API endpoint
Save the following as payload.json
```json
{
   "key": "PASTE_YOUR_PRIMARY_CLUSTER_UNSEAL_KEY_HERE",
   "nonce": "PASTE_THE_NONCE_OUTPUT_HERE"
}
```
Make the request and save as a variable named ENCODED_TOKEN
```sh
ENCODED_TOKEN=$(curl -s \
  --request PUT \
  --data @payload.json \
  http://127.0.0.1:8204/v1/sys/replication/dr/secondary/generate-operation-token/update | jq .encoded_token)
```
Example output:
```json
{  
   "nonce":"NONCE",
   "started":true,
   "progress":1,
   "required":1,
   "complete":true,
   "encoded_token":"ENCODED_TOKEN",
   "encoded_root_token":"",
   "pgp_fingerprint":""
}
```
Next the DR operation token can be decoded via the following command

```sh
DR_OPERATION_TOKEN=$(vault3 operator generate-root -dr-token -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
```

Now that the DR token has been obtained, we can perform a failover test and validate the information is present on the DR secondary cluster.
Also, we'll validate that an authentication token is valid on both the primary AND the DR secondary.

First we'll login with a normal user to obtain an authentication token for validation purposes
```sh
vault login -method=userpass username=drtest password=drtest
```
Confirm this user can read a secret
```sh
vault read supersecret/drtest
```
Now we'll stow the authentication token for this user
```sh
cp ~/.vault-token ~/.vault-token-DRTEST
diff ~/.vault-token ~/.vault-token-DRTEST
```

To perform the failover test, we can either disable replication on the primary, or demote the primary to a secondary.

OPTION 1 - Disable replication 
```sh
vault login root
vault write -f /sys/replication/dr/primary/disable
vault write -f /sys/replication/performance/primary/disable
```

Now check replication status on the primary
```sh 
curl -s http://127.0.0.1:8200/v1/sys/replication/status | jq
{
  "request_id": "2e480045-e853-5981-815a-5668d8957234",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "dr": {
      "mode": "disabled"
    },
    "performance": {
      "mode": "disabled"
    }
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```
Check the DR secondary as well
```sh
curl -s http://127.0.0.1:8204/v1/sys/replication/status | jq
{
  "request_id": "d0c4e7e2-c471-5a5c-1ab6-ee7d83ea78bd",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "dr": {
      "cluster_id": "2f665cf6-52f4-f83a-4de0-d873996ba7f4",
      "known_primary_cluster_addrs": [
        "https://127.0.0.1:8201"
      ],
      "last_reindex_epoch": "1575783991",
      "last_remote_wal": 116,
      "merkle_root": "54053ece286cefba93efd22dd83593357488545a",
      "mode": "secondary",
      "primary_cluster_addr": "https://127.0.0.1:8201",
      "secondary_id": "vault3",
      "state": "stream-wals"
    },
    "performance": {
      "mode": "disabled"
    }
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

OPTION 2 - Demotion of replication role 
Demote primary to secondary
```sh
vault write -f /sys/replication/performance/primary/demote
vault write -f /sys/replication/dr/primary/demote
```

---

Continue with the test once one of the above options has been completed.

---

Validate that secrets can be accessed on the performance secondary
```sh
vault2 login -method=userpass username=drtest password=drtest
vault2 read supersecret/drtest
```

Note that the .vault-token has changed when you authenticate to the secondary cluster
```sh
diff ~/.vault-token ~/.vault-token-DRTEST
```

Next, promote DR secondary to primary, with the DR operation token (remember that the variables we've used are ephemeral and only good within a single shell session)
```sh
vault3 write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}
```


Check status
```sh
vault3 read -format=json sys/replication/status | jq
{
  "request_id": "56efd503-f403-09f0-971a-ff1329b735e9",
  "lease_id": "",
  "lease_duration": 0,
  "renewable": false,
  "data": {
    "dr": {
      "cluster_id": "2f665cf6-52f4-f83a-4de0-d873996ba7f4",
      "known_secondaries": [
        "vault"
      ],
      "last_reindex_epoch": "0",
      "last_wal": 89,
      "merkle_root": "43e3dc7c4085dea37a2a71a45b09e7d807652add",
      "mode": "primary",
      "primary_cluster_addr": "",
      "state": "running"
    },
    "performance": {
      "cluster_id": "07db81d4-b2b5-e75b-6db0-5ebb74ffcffd",
      "known_secondaries": [
        "vault2"
      ],
      "last_reindex_epoch": "0",
      "last_wal": 89,
      "merkle_root": "dc483cfebadadd9bbf16101f23f7221fa53e30de",
      "mode": "primary",
      "primary_cluster_addr": "",
      "state": "running"
    }
  },
  "warnings": null
}
```

Now let's validate that our original authentication token is valid 
```sh
cp ~/.vault-token-DRTEST ~/.vault-token
vault3 read supersecret/drtest
 Key             	Value
 ---             	-----
 refresh_interval	768h0m0s
 password        	baines
 username        	harold
```

SUCCESS!



The environment looks like the following at this step:

```
+---------------------------------+                    +------------------------------------+
| vault port:8200                 |                    | vault2 port:8202                   |
| Replication disabled            |                    | Performance secondary replication  |
| (or demoted)                    |                    | vault3 --> vault2                  |
|                                 |                    |                                    |
+---------------------------------+                    +------------------------------------+

                                                                          ^
                                                                          |
                                                                          |
                                                                          |
+---------------------------------+                                       |
| vault3 port:8204                |                                       |
| DR primary replication          |  +------------------------------------+
| Performance primary replication |
| vault3 --> vault2               |
+---------------------------------+
```


FAILBACK for the first Vault cluster


Enable vault as DR secondary to vault3
This will ensure if there are changes to the replication set (data; that is policies/secrets and so forth), that the changes are propagated back to the original primary (vault).

NOTE - after DR promotion vault3 is already configured as DR primary as it inherited that role from vault
```sh
vault3 login root
vault3 write -f /sys/replication/dr/primary/enable
PRIMARY_DR_TOKEN=$(vault3 write -format=json /sys/replication/dr/primary/secondary-token id=vault | jq --raw-output '.wrap_info .token' )
vault login root
vault write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}
```

vault3 is now replicating (DR) to vault, the environment is as follows
```
+---------------------------------+                    +------------------------------------+
| vault port:8200                 |                    | vault2 port:8202                   |
| DR secondary replication        |                    | Performance secondary replication  |
| (vault3 --> vault)              |                    | vault3 --> vault2                  |
|                                 |                    |                                    |
+---------------------------------+                    +------------------------------------+

            ^                                                             ^
            |                                                             |
            |                                                             |
            |                                                             |
+---------------------------------+                                       |
| vault3 port:8204                |                                       |
| DR primary replication          |  +------------------------------------+
| Performance primary replication |
| vault3 --> vault2               |
+---------------------------------+
```


Promote original Vault instance back to disaster recovery primary
```sh
DR_OTP=$(vault operator generate-root -dr-token -generate-otp)
NONCE=$(vault operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
ENCODED_TOKEN=$(vault operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )
DR_OPERATION_TOKEN=$(vault operator generate-root -dr-token -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
vault write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}
```

Demote vault 3 to secondary to return to original setup as DR secondary
```sh
vault3 write -f /sys/replication/performance/primary/demote
vault3 write -f /sys/replication/dr/primary/demote
```

Now we will update the primary address for the DR secondary cluster (vault3)
```sh
PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id=vault3 | jq --raw-output '.wrap_info .token' )
DR_OTP=$(vault3 operator generate-root -dr-token -generate-otp)
NONCE=$(vault3 operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
ENCODED_TOKEN=$(vault3 operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )
DR_OPERATION_TOKEN=$(vault3 operator generate-root -dr-token -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
vault3 write sys/replication/dr/secondary/update-primary dr_operation_token=${DR_OPERATION_TOKEN} token=${PRIMARY_DR_TOKEN}
```




The environment looks like the following at this step:
```
+---------------------------------+                    +------------------------------------+
| vault port:8200                 |                    | vault2 port: 8202                  |
| Performance primary replication |    +----------->   | Performance secondary replication  |
| DR primary replication          |                    | (vault -> vault2)                  |
|                                 |                    |                                    |
+---------------------------------+                    +------------------------------------+

               +
               |
               v

+---------------------------------+
| vault3 port:8204                |
| DR secondary replication        |
| (vault -> vault3)               |
|                                 |
+---------------------------------+
```


Check status on all 3
```sh
vault read -format=json sys/replication/status | jq
vault2 read -format=json sys/replication/status | jq
vault3 read -format=json sys/replication/status | jq
```

Clean up. CTRL-C running Vault sessions, clean up of tokens
```sh
rm -f ~/.vault-token*
pkill vault
```
