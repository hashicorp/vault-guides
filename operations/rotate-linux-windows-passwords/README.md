# Simple Password Rotation with HashiCorp Vault
This guide demonstrates an automated password rotation workflow using Vault and a simple Bash script. These scripts could be run in a cron job or scheduled task to dynamically update local system passwords on a regular basis.

NOTE: This is *not* the be-all and end-all of password rotation. It is also not a PAM tool. It can do the following:

* Rotate local system passwords on a regular basis
* Allow systems to rotate their own passwords
* Store login credentials securely in Vault
* Ensure that passwords meet complexity requirements
* Require users to check credentials out of Vault 

In this demo you'll have three terminal windows open. One for running Vault, a second for entering Vault CLI commands, and one for your remote Linux server. The scripts run from the remote GCP instance and connect to Vault to update their stored credentials.

## Prerequisites
* Vault installed on your local machine: https://www.vaultproject.io/downloads.html
* GCP account and SDK command line tools installed: https://cloud.google.com/sdk/

## Estimated Time to Complete
10 minutes

### Step 1: Configure Vault on your local machine
In a new terminal, run the following commands to get Vault setup on your laptop:

```
vault server -dev -dev-root-token-id=root
```

Leave Vault running in this terminal. You can point out API actions as they are logged, such as revoked leases, etc.

### Step 2: Configure a policy
Open the Vault UI at http://127.0.0.1:8200 and create an ACL policy called `rotate-linux` with the following content:

```
path "secret/data/linux/*" {
  capabilities = ["create", "read", "update", "list"]
}
```

### Step 3: Generate a token
Open a second terminal and generate a token for use in Step 5.
```
export VAULT_ADDR=http://127.0.0.1:8200
vault token create -period 24h -policy rotate-linux
```

### Step 4: Configure a Linux instance
Open a third terminal window and run the following commands. The first one creates a new Linux instance in GCP. The second command copies our password rotation script to the remote host. The third establishes an SSH connection to the remote host, while enabling a tunnel back to Vault on our local machine.

```
gcloud compute instances create linuxdemo \
  --zone us-central1-a \
  --image-family=ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud

# You may have to wait a few seconds before running the next command. GCP is fast, but not *that* fast.

gcloud compute scp --zone us-central1-a \
  files/rotate_linux_password.sh \
  linuxdemo:/tmp/rotate_linux_password.sh

gcloud compute ssh --zone us-central1-a linuxdemo -- -p 22 -R 8200:localhost:8200
```

### Step 5: Rotate the root password
Run these commands on the linuxdemo instance. Use the Vault token you created in Step 2. You do not need to install Vault on this Linux instance. The update script uses the built-in `curl` command to securely save newly generated credentials in Vault. The script requires three arguments, the username, the length of the randomly generated password, and your Vault URL.
```
sudo /bin/su - root
cd /tmp
export VAULT_ADDR=http://127.0.0.1:8200
# Don't forget to replace with the token you created in step #3 here!
export VAULT_TOKEN=4ebeb7f9-d691-c53f-d8d0-3c3d500ddda8
./rotate_linux_password.sh root 12 $VAULT_ADDR
```

### Step 6: 
Open your local Vault UI on `http://127.0.0.1:8200` and show the root password. It is stored in `secret/linux/linuxdemo/root_creds`. Run the script from step 5 again and show it update.

## Optional Extras

### Show older versions of the credentials
Here you can talk about versioned KV and how older versions of the credentials are still accessible. You might need them for forensics or to know which password was used at a particular time in the past. These commands can be run from the linuxdemo instance.
```
export VAULT_TOKEN=root
export VAULT_ADDR=http://127.0.0.1:8200
apt install -y jq
curl -X GET -H "X-Vault-Token: $VAULT_TOKEN" ${VAULT_ADDR}/v1/secret/data/linux/linuxdemo/root_creds?version=1 | jq .
curl -X GET -H "X-Vault-Token: $VAULT_TOKEN" ${VAULT_ADDR}/v1/secret/data/linux/linuxdemo/root_creds?version=2 | jq .
```

### Do it on Windows
A Windows Powershell script and sample policy are provided for Windows users. You'll need a running Vault instance and a token for the script to run. Usage is exactly the same as for the bash script in the example above. The script was tested on a Windows 2016 server instance.

### Use longer phrase-based passwords
Security experts recommend using a really long password based on words that you can remember easily. Relevant XKCD: https://xkcd.com/936/

To enable this feature, simply uncomment the relevant lines in the bash or powershell script. For the Linux version you'll need the optional 'bashpass' utility installed. https://github.com/joshuar/bashpass

## Cleanup
Run this to delete your demo instance:
```
gcloud compute instances delete linuxdemo
```