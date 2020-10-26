# Vault Mock Secrets Plugin

Mock is an example secrets engine plugin for [HashiCorp Vault](https://www.vaultproject.io/). It is meant for demonstration purposes only and should never be used in production.

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

# Enable the Mock plugin
$ make enable

# Create a new user, "john" with password, "password"
$ vault write auth/mock-auth/user/john password=password
```

To login using the mock auth method:

```
$ vault write auth/mock-auth/login user=john password=password

Key                  Value
---                  -----
token                s.PRjzJuKTWKlYc1jbGPLh5ghX
token_accessor       oyQxJRrWnhR8bhoZY0XfMq7b
token_duration       30s
token_renewable      true
token_policies       ["default" "my-policy" "other-policy"]
identity_policies    []
policies             ["default" "my-policy" "other-policy"]
token_meta_user      john
```
