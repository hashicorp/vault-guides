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

# Write a secret to the Mock secrets engine
$ vault write mock-secrets/test hello="world"
Success! Data written to: mock/test

# Retrieve secret from Mock secrets engine
$ vault read mock-secrets/test
Key      Value
---      -----
hello    world
```

## License

Mock was contributed to the HashiCorp community by [hasheddan](https://github.com/hasheddan/vault-plugin-secrets-covert). In doing so, the original license has been removed.
