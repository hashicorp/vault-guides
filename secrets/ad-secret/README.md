#  Active Directory Secrets Engine
This guide shows how to configure Vault's AD Secrets Engine, and suggestions for configuration on the AD Server side.

## Estimated Time to Complete
This exercise should take 5-30 minutes, depending of how much configuration is needed on the Active Directory side.

## Steps to configure the Active Directory Server
As described in [this Microsoft document][ldap-tls], LDAP password changes are only allowed over TLS connections, therefore a certificate must be configured and exported to Vault.

### 1- Create Windows Server 2016 Datacenter Instance
TODO - Terraform code
#### Azure:

- Make an Azure Resource Group (vault-ad-test)
- Create a Windows Server 2016 Datacenter instance in the new Resource Group
- Machine Name: vault-ad-test
- Username: vault-ad-test
- Password: YOUR-PASSWORD
- A1 Standard
- Static IP  (XX.XX.XX.XX) (if dynamic ip, it can change when you reboot)
- Allow inbound ports 389 (LDAP) and 636 (LDAPS … ANY protocol). Use non-overlapping priorities.
- Enable auto-shutdown
- View the instance and download the RDP info from “Connect”

#### AWS:
same

### 2- Install and Configure Active Directory Server
RDP into instance
Follow the steps described here, with a few caveats:
- Do not change DNS address
- It is not necessary to install .Net 3.5 
- *The Root Domain name will be used in your TLS certificate and as the server URL*

https://blogs.technet.microsoft.com/canitpro/2017/02/22/step-by-step-setting-up-active-directory-in-windows-server-2016/

### 3- Configure TLS/SSL for Active Directory Server
Follow the steps described in this video, with the caveat:
- *Do not change the defaults of CA Name configuration*
- Reboot computer once done

https://www.youtube.com/watch?v=JFPa_uY8NhY

### 4- Test Locally
First, let's configure Windows to find the AD Server using the domain name.

Open Powershell, or cmd, type
```
notepad C:\Windows\System32\drivers\etc\hosts
```
Append the following line, replacing with your domain: 
```
127.0.0.1  [YOUR AD ROOT DOMAIN HERE]
```

Again on Powershell or cmd, type
```
ldp
```
Click on "Connect", enter your AD ROOT DOMAIN, port 389. This validates ldap connection.

Click on "Connect", enter your AD ROOT DOMAIN, port 636, check "SSL". This validates ldaps connection.

### 5- Test Remotely
We need to export the certificate and share with the remote client.

On Powershell or cmd, type:
```
mmc
```
Add snap-in: Certificate > Computer account > Local Computer.

Click on Certificates > Trusted Root Certification Authorities > Certificates

Find your certificate with column "Intended Purposes - Client Auth", right click, All Tasks, Export

In the Export Wizard, don't export private key and select "Base-64 encoded X.509"

Save certificate. If you open it on Notepad, if should follow the format:
```
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

Share the certificate with remote computer.

#### Add certificate to trust chain:
##### Mac
- Double click certificate to open "Keychain Access"
- Find certificate under the "login" tab on top left
- Copy and past under "System", so that all users and services in this machine can retrieve this certificate
- Under "System", right click certificate, click on "Trust" and change to "Always trust"
- If you have a terminal open, you will need to open a new one to update the trusted certificates available in the session

#### Linux Rhel
Execute:
```
sudo cp YOUR-CERTIFICATE-FILE-NAME.cer /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust enable; sudo update-ca-trust extract
```
Close this terminal and open a new one to update the trusted certificates available

#### Test
Execute:
```
## Update /etc/hosts
echo 'AD-SERVER-IP-HERE YOUR-AD-ROOT-DOMAIN-HERE' >> /etc/hosts
ldapsearch -x -H ldaps://YOUR-AD-ROOT-DOMAIN-HERE -d1

# You can add the flag -d1 for verbose output
# For Linux Rhel you can install ldapsearch by executing
# yum install openldap*
```
Expected output:
```
...
text: 000004DC: LdapErr: DSID-0C090A22, comment: In order to perform this opera
 tion a successful bind must be completed on the connection., data 0, v3839
... 
```
The above represents success - AD Server was reached but no AD account was given.

### 6- Create AD Vault user and test user
In the Windows Server, click on Search type "dsa.msc" to open "Active Directory Users and Computers"

- Open your ROOT-DOMAIN and add a new user for vault-admin under the "Users" folder
- Left click on "Users", and select "Delegate Control"
- Type user name, click "check name" and next
- Click "Create a custom task"
- Click "Only the following ..." and select "Users" (last item)
- Click "General" and "Property specific"
- Click "Change Password" and "Reset Password" (near start of list) and "Read userAccountControl" and "Write userAccountControl" (near the end of list)

- Create another user under the "Users" folder, to test password rotation


### 7- Configure Vault
This is the easy part!

Note: ensure you have updated your hosts file to point the "YOUR-AD-ROOT-DOMAIN" to the Windows Server IP address.

In a workstation with Vault client and a copy of the above cert, execute
```
vault secrets enable ad
# Example userdn if your users are in the default "Users" folder:
# userdn="CN=Users,DC=example,DC=net"

export USERNAME=YOUR-VAULT-USERNAME-IN-AD@YOUR-AD-ROOT-DOMAIN
export PASSWORD=YOUR-VAULT-USER-IN-AD-PASSWORD

vault write ad/config     binddn=$USERNAME     bindpass=$PASSWORD     url=ldaps://YOUR-AD-ROOT-DOMAIN-HERE     userdn="SEE-EXAMPLE-ABOVE" certificate=@PATH-TO-CERTIFICATE

vault write ad/roles/ROLE-NAME  service_account_name="USER-NAME@YOUR-AD-ROOT-DOMAIN"
vault read ad/creds/ROLE-NAME
# On the first execution, previous password won't be shown.
```

[ldap-tls]: https://support.microsoft.com/en-us/help/269190/how-to-change-a-windows-active-directory-and-lds-user-password-through