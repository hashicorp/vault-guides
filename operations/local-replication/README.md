# Local replication
Vault is a lightweight binary that runs as a single process. This allows multiple Vault processes to easily run on a single machine, which is useful for testing/validation of Vault capabilities, as well as for development purposes. In this example, we will run three Vault processes to validate Vault replication capabilities and operations.

The first Vault will be the primary, both for performance and for DR replications. The second Vault will be the secondary for performance, while the third will be the secondary for DR. 

More information on performance and DR replication can be found https://www.vaultproject.io/docs/enterprise/replication/index.html 

Note: Requires Vault Enterprise binary in your local OS flavor. Instructions assume bash and common shell operations.

# Bash alias setup

Store the following in your .bash_profile/.bashrc or whatever

NOTE: the commands in here are specific to Vault version >= 0.8

```
alias vrd='VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8200 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8200 -dev-ha -dev-transactional'
alias vrd2="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8202 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8202 -dev-ha -dev-transactional"
alias vrd3="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8204 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8204 -dev-ha -dev-transactional"
alias vrd4="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8206 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8206 -dev-ha -dev-transactional"

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

Spin it up locally on laptop in three separate terminals
```sh
vrd
vrd2
vrd3
vrd4
```

Make sure you write down the unseal key of "vrd" for DR setup command.

Vault UI links:  
http://127.0.0.1:8200  
http://127.0.0.1:8202  
http://127.0.0.1:8204  
http://127.0.0.1:8206  

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

setup performance replication (vault->vault2)
```sh
vault login root
vault write -f sys/replication/performance/primary/enable
sleep 10
PRIMARY_PERF_TOKEN=$(vault write -format=json sys/replication/performance/primary/secondary-token id=vault2 \
  | jq --raw-output '.wrap_info .token' )
vault2 login root
vault2 write sys/replication/performance/secondary/enable token=${PRIMARY_PERF_TOKEN}

```

Validation:
```
curl     http://127.0.0.1:8200/v1/sys/replication/status | jq

```sh
# Response:
{  
   ...
   "data":{  
      "dr":{  
         "mode":"disabled"
      },
      "performance":{  
         "cluster_id":"8c31e8c1-0b1e-6aec-db70-323bad86eedc",
         "known_secondaries":[  
            "vault2"
         ],
         ...
         "mode":"primary",
         "primary_cluster_addr":""
      }
   },
   ...
}


curl     http://127.0.0.1:8202/v1/sys/replication/status | jq

# Response:
{  
   ...
   "data":{  
      "dr":{  
         "mode":"disabled"
      },
      "performance":{  
         "cluster_id":"8c31e8c1-0b1e-6aec-db70-323bad86eedc",
         "known_primary_cluster_addrs":[  
            "https://127.0.0.1:8201"
         ],
         ...
         "primary_cluster_addr":"https://127.0.0.1:8201",
         "secondary_id":"vault2",
         "state":"stream-wals"
      }
   },
   ...
}
```

setup DR replication (vault -> vault3)
```sh
vault login root
vault write -f /sys/replication/dr/primary/enable
sleep 10
PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id="vault3" | jq --raw-output '.wrap_info .token' )
vault3 login root
vault3 write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}

```

## Optional 4th cluster to provide DR performance secondary (vault2) 
setup DR replication (vault2 -> vault4)

```
vault2 login root 
vault2 write -f sys/replication/dr/primary/enable
PRIMARY_DR_TOKEN=$(vault2 write -format=json /sys/replication/dr/primary/secondary-token id=vault4 | jq --raw-output '.wrap_info .token' )

vault4 login root
vault4 write sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}

```

Validation:
```
curl     http://127.0.0.1:8206/v1/sys/replication/status | jq
# Response:
{
  ...
  "data": {
    "dr": {
      "cluster_id": "5bbaa867-9ff1-0c6c-ca12-ce2229ab2492",
      "known_primary_cluster_addrs": [
        "https://127.0.0.1:8203"
      ],
      "last_reindex_epoch": "1554346757",
      "last_remote_wal": 373,
      "merkle_root": "9efcabe3e1c31f25ffd8b0336740d4126afd4868",
      "mode": "secondary",
      "primary_cluster_addr": "https://127.0.0.1:8203",
      "secondary_id": "vault4",
      "state": "stream-wals"
    },
    "performance": {
      "mode": "disabled"
    }
  },
  ...
```
Now let's test DR. First we need to securely share a root token useable for Vault 3. The secure share is allowed by using "one time password"

generate DR operation token (used to promote DR secondary)
```
export VAULT_ADDR3=http://127.0.0.1:8204
## Validate process hasn't started
curl     $VAULT_ADDR3/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq

## Generate one time password (otp) 
DR_OTP=$(vault3 operator generate-root -dr-token -generate-otp)

## Initiate DR token generation, create nonce
NONCE=$(vault3 operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')

## Validate process has started

curl     $VAULT_ADDR3/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq


## Generate the encoded token using the unseal key from DR primary 
## as well as the nonce generated from prior execution.
##
## Note that production clusters would normally require several executions 
## to correlate with the Shamir sharing threshold number of keys

PRIMARY_UNSEAL_KEY= PASTE UNSEAL KEY HERE

## Initiate DR token generation, provide unseal keys (1 unseal key in our example)
## THIS IS BROKEN IN 0.9.5,0.9.6 AND WILL BE FIXED IN 0.10
ENCODED_TOKEN=$(vault3 operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )

## API workaround for above:

## create payload.json
## {
##   "key": "UNSEAL-KEY-VAULT-1",
##   "nonce": "NONCE"
## }

ENCODED_TOKEN=$(curl \
--request PUT \
    --data @payload.json \
    $VAULT_ADDR3/v1/sys/replication/dr/secondary/generate-operation-token/update | jq .encoded_token)

## Output:
## {  
##    "nonce":"NONCE",
##    "started":true,
##   "progress":1,
##   "required":1,
##   "complete":true,
##   "encoded_token":"ENCODED_TOKEN",
##   "encoded_root_token":"",
##   "pgp_fingerprint":""
## }
##


DR_OPERATION_TOKEN=$(vault operator generate-root -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
```


create admin  user
```
vault login root
# setup vault admin user
vault auth enable userpass

# create vault user policy
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write vault-admin -

vault write auth/userpass/users/vault password=vault policies=vault-admin

```

create regular user and write some data
```
vault login root
vault write auth/userpass/users/drtest password=drtest policies=user

echo '
path "supersecret/*" {
  capabilities = ["list", "read"]
}' | vault policy write user -
vault secrets enable -path=supersecret generic
vault write supersecret/drtest username=harold password=baines
```

Perform a failover test
```
# auth to vault with regular user
vault login -method=userpass username=drtest password=drtest

vault read supersecret/drtest
# save the ephemeral token for verification
cp ~/.vault-token ~/.vault-token-DRTEST
diff ~/.vault-token ~/.vault-token-DRTEST

### STOP primary vault instance  - in dev mode this blows away all cluster information
### cntrl + c in the terminal windowd that you used to run vrd,  or pkill -fl 8200 
### This will kill the primary Vault cluster, but you probably want to use the Option 1 or 2 below

# OPTION 1 - Disable replication
# disable replication on primary
vault login root

vault write -f /sys/replication/dr/primary/disable
vault write -f /sys/replication/performance/primary/disable

# Response
```sh 
curl http://127.0.0.1:8200/v1/sys/replication/status | jq
# Response
{  
   ...
   "data":{  
      "dr":{  
         "mode":"disabled"
      },
      "performance":{  
         "mode":"disabled"
      }
   },
   ...
}

curl     http://127.0.0.1:8202/v1/sys/replication/status | jq
# Response:
{  
   ...
   "data":{  
      "dr":{  
         "mode":"disabled"
      },
      "performance":{  
         "cluster_id":"b0e7cfb8-d453-0919-48b2-9c2f33bdfee7",
         "known_primary_cluster_addrs":[  
            "https://127.0.0.1:8201"
         ],
         "last_remote_wal":390,
         "last_wal":695,
         "merkle_root":"c0c2622f5960fce19420a0657f6b545dbe81fb7f",
         "mode":"secondary",
         "primary_cluster_addr":"https://127.0.0.1:8201",
         "secondary_id":"vault2",
         "state":"stream-wals"
      }
   },
   ...
}

# OPTION 2 - Demotion of replication role 
# demote primary to secondary
vault write -f /sys/replication/performance/primary/demote

## demoting dr primary to secondary puts it in cold standby
# vault write -f /sys/replication/dr/primary/demote

# check performance secondary for access to secrets etc
vault2 login -method=userpass username=drtest password=drtest
vault2 read supersecret/drtest

# note that the .vault-token has changed
diff ~/.vault-token ~/.vault-token-DRTEST

## Promote DR secondary to primary
vault3 write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}

## Make vault DR secondary to vault3 (primary)
vault3 login root
PRIMARY_DR_TOKEN=$(vault3 write -format=json /sys/replication/dr/primary/secondary-token id=vault | jq --raw-output '.wrap_info .token' )
vault login root
vault write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}

# check status
vault3 read -format=json sys/replication/status | jq

# let's check our token status
cp ~/.vault-token-DRTEST ~/.vault-token
vault3 read supersecret/drtest

# vault3 read supersecret/drtest
## Key             	Value
## ---             	-----
## refresh_interval	768h0m0s
## password        	baines
## username        	harold

## SUCCESS!

```

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


FAILBACK - Option 1  - relevant for Vault 0.8-0.9
Note that this is not an ideal situation today, as we must first sync DR replication set back to vault, then perform another failover such that vault is the perf primary/dr primary.
```
# Disable replication on vault (if not already done)
vault write -f /sys/replication/dr/primary/disable
vault write -f /sys/replication/performance/primary/disable

# enable vault as DR secondary to vault3
vault3 login root
vault3 write -f /sys/replication/dr/primary/enable
PRIMARY_DR_TOKEN=$(vault3 write -format=json /sys/replication/dr/primary/secondary-token id=vault | jq --raw-output '.wrap_info .token' )
sleep 10
vault login root
vault write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}
sleep 10  
```

FAILBACK - Option 2 - relevant for Vault >= 0.9.1
This scenario assumes the primary was demoted
```
#Enable vault as DR secondary to vault3
vault3 login root
vault3 write -f /sys/replication/dr/primary/enable
PRIMARY_DR_TOKEN=$(vault3 write -format=json /sys/replication/dr/primary/secondary-token id=vault | jq --raw-output '.wrap_info .token' )
vault login root
vault write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}

# Promote original Vault instance back to disaster recovery primary
DR_OTP=$(vault operator generate-root -dr-token -generate-otp)
NONCE=$(vault operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
ENCODED_TOKEN=$(vault operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )
DR_OPERATION_TOKEN=$(vault operator generate-root -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
vault write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}
vault write -f /sys/replication/dr/primary/enable

#Demote vault 3 to secondary to return to original setup 
NEW_PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id=vault3 | jq --raw-output '.wrap_info .token' )
vault3 write -f /sys/replication/dr/primary/demote
vault3 write /sys/replication/dr/secondary/update-primary primary_api_addr=127.0.0.1:8200 token=${NEW_PRIMARY_DR_TOKEN}

# Promote original Vault instance back to performance primary
vault write -f /sys/replication/performance/secondary/promote
vault2 write -f /sys/replication/performance/primary/demote
NEW_PRIMARY_PERF_TOKEN=$(vault write -format=json sys/replication/performance/primary/secondary-token id=vault2 \
  | jq --raw-output '.wrap_info .token' )
vault2 write /sys/replication/performance/secondary/update-primary primary_api_addr=127.0.0.1:8200 token=${NEW_PRIMARY_PERF_TOKEN}


```



The environment looks like the following at this step:

```
+---------------------------------+                    +------------------------------------+
| vault                           |                    | vault2 port: 8202.                 |
| DR secondary replication        | +-------------->   | Performance secondary replication  |
| vault3->vault                   |                    | vault3 --> vault2                  |
|                                 |                    |                                    |
+---------------------------------+                    +------------------------------------+

              ^                                                           
              |                                                           
              |                                                           
              +                                                           
+---------------------------------+                                       
| vault3 port:8204                |                                       
| DR primary replication          |  
| Performance primary replication |
| vault3 --> vault2               |
+---------------------------------+
```



```
# now we fail vault3 and enable vault as the primary
vault3 write -f /sys/replication/dr/primary/disable
vault3 write -f /sys/replication/performance/primary/disable

# now setup vault as DR primary to vault3
vault login root
vault write -f /sys/replication/dr/secondary/promote key=<<PASTE KEY HERE FROM VAULT here>>
vault write -f /sys/replication/dr/primary/disable
vault write -f /sys/replication/dr/primary/enable
PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id=vault3 | jq --raw-output '.wrap_info .token' )
sleep 10
vault3 login root
vault3 write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}
sleep 10  
```


check status on all 3
```
vault read -format=json sys/replication/status | jq
vault2 read -format=json sys/replication/status | jq
vault3 read -format=json sys/replication/status | jq
```

Clean up
```
# CTRL-C any running vrd sessions
rm -f ~/.vault-token*
```
