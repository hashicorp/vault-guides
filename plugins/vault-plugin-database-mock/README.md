# Vault Mock Database Plugin

Mock is an example database engine plugin for [HashiCorp Vault](https://www.vaultproject.io/). It is meant for demonstration purposes only and should never be used in production.

## Usage

All commands can be run using the provided [Makefile](./Makefile). However, it may be instructive to look at the commands to gain a greater understanding of how Vault registers plugins. Using the Makefile will result in running the Vault server in `dev` mode. Do not run Vault in `dev` mode in production. The `dev` server allows you to configure the plugin directory as a flag, and automatically registers plugin binaries in that directory. In production, plugin binaries must be manually registered.

This will build the plugin binary and start the Vault dev server:

```
# Build Mock plugin and start Vault dev server with plugin automatically registered
$ make
```

Now open a new terminal window and run the following commands:

```
# Open a new terminal window and export Vault dev server http address
$ export VAULT_ADDR='http://127.0.0.1:8200'

# Enable the Mock database plugin
$ make enable

# Retrieve database credentials from the secrets engine
$ vault read database/creds/mock-role
Key                Value
---                -----
lease_id           database/creds/mock-role/voIwi51mOWzhdhGK1j3Xt92g
lease_duration     5m
lease_renewable    true
password           mvYgYUC55X-K05y35H84
username           v_token_mock_role_oeshdtguahgwplg2p66b_1631316568
```
