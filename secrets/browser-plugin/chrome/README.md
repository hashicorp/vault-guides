These assets are provided to perform the tasks described in the [Vault Secrets in a Browser Plugin](https://learn.hashicorp.com/tutorials/vault/browser-plugin) tutorial.

-------

# vaultPass

A Browser extension to leverage Hashicorp Vault as Credential Storage for teams

A project started on a Hackathon @ ironSource by [Dimitry1987](https://github.com/Dmitry1987) and continued by [Chris Blum](https://github.com/zeichenanonym)

**Get it:**
[Chrome Store](https://chrome.google.com/webstore/detail/vaultpass/kbndeonibamcpiibocdhlagccdlmefco)
[Firefox AMO](https://addons.mozilla.org/en-GB/firefox/addon/vaultpass/)


## Setup

The plugin assumes that you have access to a Vault sever with the userpass
authentication method created. The user that logins needs to have access to the
a KV-V2 secrets engine mounted at the path `vaultpass`.

```shell
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200
vault auth enable userpass
vault secrets enable -path=vaultpass kv-v2
vault policy write vault_pass-policy - <<EOF
path "vaultpass/*" {
  capabilities = [ "read", "create" ]
}
EOF

vault write auth/userpass/users/browser \
  password=browser \
  policies=vault_pass-policy


```
