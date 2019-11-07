# Download the current vault-pki-monitor-venafi release zip package for your operating system (https://github.com/Venafi/vault-pki-monitor-venafi/releases/) along with its checksum for the binary. There are two versions of binaries, optional and strict. The "optional" version allows certificates to be issued by the Vault CA when there is no Venafi policy applied whereas the "strict" will return an error when there is no Venafi policy applied, "policy data is nil". 
curl -fOSL https://github.com/Venafi/vault-pki-monitor-venafi/releases/download/0.4.0%2B181/vault-pki-monitor-venafi_0.4.0+181_linux_strict.zip
curl -fOSL https://github.com/Venafi/vault-pki-monitor-venafi/releases/download/0.4.0%2B181/vault-pki-monitor-venafi_0.4.0+181_linux_strict.SHA256SUM

# Unzip the plugin binary and check it with sha256
unzip vault-pki-monitor-venafi_0.4.0+181_linux_strict.zip
sha256sum -c vault-pki-monitor-venafi_0.4.0+181_linux_strict.SHA256SUM

# Move the plugin binary to the /etc/vault/vault_plugins directory (or a custom directory of your choosing)
sudo mv vault-pki-monitor-venafi_strict /etc/vault/plugins

# Give the plugin the ability to use the mlock syscall without running the process as root. The mlock syscall prevents memory from being swapped to disk.
# This command will be run on the Vault binary during a production deploy as well as each plugin since plugins run as a seperate process.
sudo setcap cap_ipc_lock=+ep /etc/vault/plugins/vault-pki-monitor-venafi_strict
