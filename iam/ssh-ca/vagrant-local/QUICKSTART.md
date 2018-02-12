# Instructions for use

1. Perform `vagrant up` within this directory
2. Login to Vault vm `vagrant ssh vault` and execute `/vagrant/1_server_setup.sh` as Vagrant user
3. Login to Client vm `vagrant ssh client` and execute `/vagrant/2_client_setup.sh` as Vagrant user
4. While logged into Client vm execute `ssh vault.example.com` as Vagrant user. It should successfully login to the Vault node using the SSH CA configuration.

# Notes

Certificate login on the host logs user specific details allowing for service account usage to still be tied to a user.

```
Oct 11 14:31:10 localhost sshd[5334]: Accepted publickey for vagrant from 192.168.50.101 port 51272 ssh2: RSA-CERT ID vault-clientrole-userpass-johnsmith-4b0473525e9941250c988f992b0204d1326885e5e51adca0b1d8debe5e102aad (serial 2914803897344261917) CA RSA 90:b5:59:62:fa:9e:0a:fa:92:75:6c:97:6c:d8:75:c7
```

Host key is signed in this configuration as well, to allow for host validation. No need to manage known_hosts file, no warnings like the following:

```
The authenticity of host '192.168.0.100 (192.168.0.100)' can't be established.
RSA key fingerprint is 3f:1b:f4:bd:c5:aa:c1:1f:bf:4e:2e:cf:53:fa:d8:59.
Are you sure you want to continue connecting (yes/no)?
```
