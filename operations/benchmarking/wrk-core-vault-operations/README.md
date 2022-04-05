# Vault Benchmarking Scripts

## Disclaimer
This repo is intended to provide guidance and will not be officially maintained by HashiCorp.

## Overview
This repository contains some Lua scripts for running benchmarks against Vault with the [wrk](https://github.com/wg/wrk) tool. They are all designed to be used with Vault's KV (Key/Value) v1 secrets engine. Most of the scripts were originally written by Roger Berlind in https://github.com/rberlind/vault-benchmarking who drew inspiration from Julia Friedman's benchmark scripts for Vault's Transit secrets engine that she wrote in https://github.com/jdfriedma/Vault-Transit-Load-Testing. More updates:
- Kawsar Kamal added the [authenticate.lua](./authenticate.lua) script for use with Vault batch tokens.
- Stenio added a Mediumblog post on [Vault benchmarking](https://medium.com/hashicorp-engineering/hashicorp-vault-performance-benchmark-13d0ea7b703f)
- Kawsar Kamal added the [read-db-secrets.lua](./read-db-secrets.lua) script for testing Dynamic Database credentials.


## Scripts
The following are the main test scripts:
1. [read-secrets.lua](./read-secrets.lua): This script randomly reads secrets from a set of N secrets under the path secret/read-test. The default value of N is 1,000. To change this, add "-- <\N\>" after the URL where \<N\> is the number of secrets you want to use. It can also print the secrets if you add "-- \<N\> true" after the URL. Use the write-secrets.lua script to populate the secrets read by this script before running it and check that you write all secrets you expect to read. The script reads them randomly over and over until it finishes.  
1. [write-random-secrets.lua](./write-random-secrets.lua): This script randomly writes secrets to a set of N secrets under the path secret/write-random-test. The default vaue of N is 1,000. By default, each secret has one key with 10-20 bytes and a second key with 100 bytes.  To change the number of distinct secrets written, add "-- <\N\>" after the URL where \<N\> is the number of secrets you want to use. The number and size of the keys could be changed, but you would need to edit the script. The script writes them randomly over and over until it finishes. There is no need to pre-populate Vault with any data for this test.
1. [write-delete-secrets.lua](./write-delete-secrets.lua): This script sequentially writes and deletes secrets. It must be run with one thread (`-t1`) and one connection (`-c1`) to ensure deletes do not reach the Vault server before the corresponding writes. However, multiple instances of this script can be run at the same time by passing an extra argument `-- <n>` after the URL, being sure to use a different value of \<n\> for each instance. Secrets for instance \<n\> of the script will be written in a sequential loop to the secret/write-delete-test path and will be named "test\<n\>-secret-\<x\>" where \<x\> is between 1 and N (default 100). This naming convention allows multiple instances of this script as well as other scripts to be run at the same time without conflict. By default, each secret has one key with 10-20 bytes and a second key with 100 bytes.  The number of distinct secrets, N, can be changed by adding an extra argument after the script identifier. In this case, you would add "-- \<identifier\> \<N\>" after the URL, using integers for both of these arguments. The number and size of the keys could be changed, but you would need to edit the script.  There is no need to pre-populate Vault with any data for this test. The last secret written might not be deleted if the final request is a write.  
1. [list-secrets.lua](./list-secrets.lua): This script repeatedly lists all secrets on the path secret/list-test. Use the write-list.lua script to populate that path with secrets. By default, that script writes 100 secrets to that path with each secret having one key with 10 bytes. If you want to print the secrets found in each list, add "-- true" after the URL.
1. [authenticate-and-revoke.lua](.authenticate-and-revoke.lua): This script repeatedly authenticates a user ("loadtester") against Vault's [userpass](https://www.vaultproject.io/docs/auth/userpass.html) authentication method and then revokes the acquired lease. (See below for instructions to enable it.)
1. [authenticate.lua](.authenticate.lua): This script repeatedly authenticates a user ("loadtester") against Vault's [userpass](https://www.vaultproject.io/docs/auth/userpass.html) authentication method. It does not issue any revocations. This can be useful for comparing authentications with batch and service token types. 
2. [read-db-secrets.lua](./read-db-secrets.lua): This script reads Dynamic postgres credentails from the role: `/v1/database/creds/benchmarking`. This Role must be configured from before and some example commands are provided below. It can also print the dynamic secrets if you add "-- \<N\> true" after the URL. 
```bash
vault secrets enable database

vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="*" connection_url="postgresql://{{username}}:{{password}}@db:5432/products" \
  username="postgres" password="password"

vault write database/roles/benchmarking \
    db_name=postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="24h" max_ttl="48h"

vault read database/creds/benchmarking
```

We also have the following utility scripts used to populate or delete secrets used by the test scripts:
1. [write-secrets.lua](./write-secrets.lua): This script writes secrets meant to be read by the read-secrets.lua script. It writes a fixed number of secrets (default 1,000) and then stops. Each secret has one key with 10-20 bytes and a second key with 100 bytes.  The number of secrets written can be changed by adding "-- \<N\>" after the URL where \<N\> is the number of secrets you want to write. The number and size of the keys could also be changed, but you would need to edit the script.
   - Note: you may want to verify that all the secrets were successfully written by reading the last secret using Vault CLI. E.g. `vault read secret/read-test/secret-1000`. If all writes were not completed successfully, you will get errors when running `read-secrets.lua`.

2. [write-list.lua](./write-list.lua): This script writes a list of secrets each having one key with 10 bytes to the path secret/list-test. These secrets are read by the list-secrets.lua script. By default it writes 100 secrets, but you can change this by adding "-- \<N\>" after the URL where \<N\> is the number of secrets you want to write.
3. [delete-secrets.lua](./delete-secrets.lua): This deletes a sequence of secrets from under a specified path. Pass the path from which you want to delete secrets by adding something like "-- secret/read-test" after the Vault URL. Do not start your path with "/v1/" or add a final "/" at the end of it since the script does this for you. The default path is "secret/test".
   - Note: deleting secrets can also be performed by disabling and enabling the secrets engine: `vault secrets disable secret && vault secrets enable -path=secret/ -version=1 kv`.

Finally, [json.lua](./json.lua) is used by some of the other scripts to decode the JSON responses from the Vault HTTP API.

## Running the Scripts together
The [run_tests.sh](./run_tests.sh) bash script runs the read-secrets.lua, list-secrets.lua, authenticate-and-revoke.lua, and 10 instances of the write-delete-secrets.lua script simultaneously. The number of instances of the last script can be changed to alter the mixture of reads, writes, and deletes. It can be run from multiple clients simultaneously as long as no instances of the write-delete-secrets.lua across these clients use the same identifier argument (\<n\>). Instances of any of the scripts can be commented out by prefacing them with a "#".  Note that while each instance of the write-delete-secrets.lua script writes to 100 secrets by default, they use distinct sets; so, the total number of secrets used by the 10 instances is 1,000. The read-secrets.lua script also uses 1,000 secrets and the list-secrets.lua script uses 100 secrets.  So, the combined number of secrets used by the run_tests.sh script in its default configuration is 2,100.

In its default configuration, the run_tests.sh script is designed to run a mixture of reads, lists, writes, deletes, authentications, and revocations consisting of about 85% reads, 5% lists, 4% writes, 4% deletes, 1% authentications, and 1% revocations. Of course, these ratios will vary somewhat depending on your cluster's configuration even if you run the script without altering it.  Making changes to the tests run in the script including removing or adding tests or changing the thread and count parameters passed to them will obviously change the mixture as well as the total throughput of your combined test.

In general, you will want to edit the run_tests.sh script or create modified versions of it before running it so you can change the duration of the tests (with the `-d` parameter) and change the names of the log files.

## Setting up userpass Auth Method

In order to run the authenticate-and-revoke.lua and authenticate.lua scripts, you need to set up the Vault [userpass](https://www.vaultproject.io/docs/auth/userpass.html) authentication method and add a user called "loadtester" with password "benchmark". The userpass Auth Method can be enabled with service or batch tokens. 

Service tokens are applicable for the `authenticate-and-revoke.lua` scripts. Use the commands below to enable using service tokens:
```
vault auth enable userpass
vault write auth/userpass/users/loadtester password=benchmark policies=default
```
Batch tokens are applicable for the `authenticate.lua` script. Use the commands below to enable using batch tokens:
```
vault auth enable -token-type="batch" userpass
vault write auth/userpass/users/loadtester password=benchmark policies=default
```
  - Note: be careful not to run `authenticate.lua` script with service tokens. You will then end up with 1000s of outsanding leases. If this happens, please use this command to delete all outstanding leases: `vault auth disable userpass`; it may take a long time to complete. You will then need to re-setup the Auth method.

## Configuration of wrk Client Nodes

To ensure adequate resources on the client nodes that run wrk, we suggest using a Linux node with 4 CPUs and 8 GB of RAM. You can run more than 1 node. Before following the [wrk Linux installation instructions](https://github.com/wg/wrk/wiki/Installing-wrk-on-Linux) for Ubuntu, you should run `sudo apt-get update`.

## Examples of Running the Test Scripts
See the [run_tests.sh](./run_tests.sh) script for examples of running most of the test scripts.  You should export a Vault token with permissions to read, list, write, and delete the secrets used by the tests to the VAULT_TOKEN environment variable with the command `export VAULT_TOKEN=<your_token>`.

The only test script not included in run_tests.sh is write-random-secrets.lua. It could be run and configured to write to 10,000 secrets with a command like:
```
nohup wrk -t4 -c16 -d1h -H "X-Vault-Token: $VAULT_TOKEN" -s write-random-secrets.lua http://<vault_url>:8200 -- 10000 > prod-test-write-1000-random-secrets-t4-c16-1hour.log &
```

We use "nohup" on the test scripts to ensure that the scripts continue to run if our ssh session to the node running the wrk client gets disconnected and output the results to files with the names of the files indicating the parameters used and how long they ran for.

If you want the read-secrets.lua and list-secrets.lua scripts to print the secrets they retrieve, add `-- true` after the Vault URL.

When running multiple instances of the write-delete-secrets.lua script simultaneously, be sure to add the argument `-- <n>` after the URL and to use a different value of \<n\> for each instance. Please also always run this script with one thread (`-t1`) and one connection (`-c1`) to ensure deletes do not reach the Vault server before the corresponding writes.

Descriptions of the wrk command line options are [here](https://github.com/wg/wrk#command-line-options).

Notes on the parameters:
1. The "-t" parameter gives the number of threads.
1. The "-c" parameter gives the number of HTTP connections used by all threads.
1. The "-d" parameter gives the number of seconds (s), minutes (m) or hours (h) to run the test.

## Examples of Running the Utility Scripts
Here are example of running the utility scripts to populate and delete secrets needed by the test scripts:

```
# Command to write 1,000 secrets needed by the read-secrets.lua script:
wrk -t1 -c1 -d5m -H "X-Vault-Token: $VAULT_TOKEN" -s write-secrets.lua http://<vault_url>:8200 -- 1000

# Command to validate that the last secret was written. If needed, substitute 1000 for the number of secrets you supplied to write-secrets.lua script. If you get an error, you may need to run the write-secrets.lua script for a longer time.
vault read secret/read-test/secret-1000

# Command to write secrets needed by the list-secrets.lua script:
wrk -t1 -c1 -d5m -H "X-Vault-Token: $VAULT_TOKEN" -s write-list.lua http://<vault_url>:8200 -- 100

# Command to delete secrets (from secret/read-test) by disabling and enabling secrets engine
vault secrets disable secret
vault secrets enable -path=secret/ -version=1 kv

# Command to delete secrets (from secret/read-test) using delete-secrets.lua
wrk -t1 -c1 -d5m -H "X-Vault-Token: $VAULT_TOKEN" -s delete-secrets.lua http://<vault_url>:8200 -- secret/read-test
```
Note that you should specify the path from which you want to delete secrets when running the delete-secrets.lua script by adding it after the URL. The default value is "secret/test".
