# Summary
This guide demonstrates the following:
- Sentinel enforcement of Okta multi-factor authentication
- SSH certificate authority access management based on Okta MFA
- SSH one-time password access management based on Okta MFA

## Prerequisites
1. Vagrant installed
1. VirtualBox installed
1. Okta account configured  
   a. Create developer account  
   b. Create 'okta' group and add developer user account to the group  
   c. Configure multi-factor authentication with Okta Push mobile app
  

## Overview 
### Okta Authentication and Multi-Factor Authentication

### Vault SSH Certificate Authority

### Vault SSH One-Time Password

## Provision steps
Within this working directory, execute the following

```
vagrant up
```

## Usage Steps
Once Vagrant has provisioned the environment, you can login to the Web UI with your Okta credentials, and approve the login from your phone.

<img src="https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/Vault_okta_login.png" alt="okta_login" width="300">
<img src="https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/Vault_okta_mfa_push.png " alt="okta_push" width="300">


Afterwards, we can obtain our SSH credentials from the web interface for connectivity purposes.

### SSH Certificate Authority usage

1. Login to the Vault web UI
1. Navigate to Secrets, then ssh-client-signer, then `clientrole`
1. Click on the `clientrole` link
1. Login to our example client on the commandline `vagrant ssh client`
1. Copy the vagrant user's public key to the clipboard `cat ~/.ssh/id_rsa.pub`
![](https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_ssh_ca_copy_pubkey.png)
1. Paste it into the web UI at the 'Public Key' field
![](https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_ssh_ca_paste_pubkey.png)
1. Click Sign
1. Click the 'Copy key' button to copy the signed public key to the clipboard
![](https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_ssh_ca_signed_pubkey.png)
1. Within the client connection terminal, save the signed key to `~/.ssh/id_rsa-cert.pub` with the following command `echo '<paste key>' > ~/.ssh/id_rsa-cert.pub`
1. Connect to the server configured for SSH CA using the following command:
  ```
  ssh vagrant@ca.example.com
  ```
  





The SSH connection should be successful. Note that there should be NO PROMPT for SSH host validation will be presented. This method performs both client and host validation using certificates, adding additional protection against MITM attacks.


```
The authenticity of host '192.168.50.103 (192.168.50.103)' can't be established.
RSA key fingerprint is SHA256:uN6xciMWY3Lsm4Z+WXxxWkvdkCaWdf8Y4tfT8ABpPWw.
Are you sure you want to continue connecting (yes/no)?
```





### SSH One-Time Password usage

1. Login to the Vault web UI
1. Navigate to Secrets, then ssh, then `otp_key_role`
1. Click on the `opt_key_role`
1. Populate it with username 'vagrant' and host '192.168.50.102'. 
![](https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_ssh_otp_generate_creds_input.png)
1. Click 'Generate' and then you can click 'Copy Credentials' for ease of use.  

![](https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_ssh_otp_generate_creds_output.png)

On the commandline issue the following command to login to our example client

```
vagrant ssh client
```
Once at that terminal, issue the following command and enter the copied one-time password when prompted

```
ssh vagrant@192.168.50.102
```

The SSH connection should be successful. Any further attempts will fail, as the password is good for one use only!

## Tear Down Steps
Execute the following to destroy the environment. 

```
vagrant destroy -f
```
