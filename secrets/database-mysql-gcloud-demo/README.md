# Simple database secrets engine demo

This tutorial shows you how to build a simple MySQL Vault database secrets engine demo using GCP and your local machine. You will end up with three terminal sessions open. One on the MySQL server, one for running Vault commands, and a third for running the Vault server. This basically mimics an application > Vault > database architecture. 

## Prerequisites:
* Vault installed on your local machine: https://www.vaultproject.io/downloads.html
* GCP account and SDK command line tools installed: https://cloud.google.com/sdk/

## Basic Demo - Dynamic Credentials
This demo will stand up a GCP instance and install MySQL on it, configure a local Vault server, and enable the database secrets backend to manage dynamic credentials on the remote host.

### Step 1: Configure a MySQL instance
Open a terminal window and run the following commands:

```
gcloud compute instances create mysqlvaultdemo \
  --zone us-central1-a \
  --image-family=ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud
 
# You may have to wait a few seconds before running the next command. GCP is fast, but not *that* fast.

gcloud compute scp --zone us-central1-a \
  scripts/install_mysql_ubuntu.sh \
  mysqlvaultdemo:~/

gcloud compute ssh --zone us-central1-a mysqlvaultdemo -- -L 3306:localhost:3306
```

Now on the gcloud instance you just ssh'd into, run this:

```
./install_mysql_ubuntu.sh
```

The MySQL server is now ready, and port 3306 is forwarded back to your machine. Do not proceed to the next steps until the script has completely finished running.

### Step 2: Configure Vault on your local machine
In a new terminal, run the following commands to get Vault setup on your laptop:

```
vault server -dev -dev-root-token-id=root
```

Leave Vault running in this terminal. You can point out API actions as they are logged, such as revoked leases, etc.

### Step 3: Export your Vault server address
Open a third terminal for running Vault CLI commands.
```
export VAULT_ADDR=http://127.0.0.1:8200
```

### Step 4: Configure the Vault database backend for MySQL
You can copy and paste all of this code in one block:
```
vault secrets enable database

vault write database/config/my-mysql-database \
  plugin_name=mysql-database-plugin \
  connection_url="{{username}}:{{password}}@tcp(localhost:3306)/" \
  allowed_roles="my-role" username="vaultadmin" password="vaultpw"

vault write database/roles/my-role \
  db_name=my-mysql-database \
  creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" default_ttl="1h" max_ttl="24h"
```

Your Vault server is now ready. 

### Step 5: Present your demo

You are ready to present your demo.
```
# Nothing up my sleeves - note there are no dynamic users yet.
sudo mysql -uroot -pbananas -e 'select user,password from mysql.user;'

# Generate some credentials on your local machine
vault read database/creds/my-role

# Show the list of users on the MySQL server again
sudo mysql -uroot -pbananas -e 'select user,password from mysql.user;'

# Revoke the lease that was associated with those credentials. Replace with your lease id:
vault lease revoke database/creds/my-role/bb52414e-fd9c-dbf5-61ad-d9718c8b2b81

# And the dynamic credentials are gone
sudo mysql -uroot -pbananas -e 'select user,password from mysql.user;'
```

You can stop here or proceed further for a more advanced demo.

## Advanced Demo - A Vault Enabled App and Database

### Step 1: Show off the Vault UI
Log onto http://localhost:8200 in a web browser. Use `root` as the token to log on (you set this above in Step 2).

### Step 2: Create a policy in the UI
Create a policy called `db_read_only` with the following contents:
```
# Allow read only access to employees database
path "database/creds/my-role" {
    capabilities = ["read"]
}
```

### Step 3: Export your VAULT_ADDR variable:
```
export VAULT_ADDR=http://127.0.0.1:8200
```

### Step 4: Generate a periodic token for your 'app'
Generate a token for your 'app' server. Export it into a variable for ease of use. Replace with *your* token. 
```
vault token create -period 1h -policy db_read_only
export APP_TOKEN=47b422f4-ddeb-671a-756a-c161b66a84dd
```

Now you can fetch credentials with it:
```
curl -H "X-Vault-Token: $APP_TOKEN" \
     -X GET ${VAULT_ADDR}/v1/database/creds/my-role | jq .
```

### Step 5: Log on to MySQL using the dynamic credentials
For this bit you'll need a MySQL client installed on your laptop. The setup script loads a sample database called employees that you can browse. You will be mimicing the behavior of an application interacting with Vault and a MySQL database.

```
# Use the creds to log on. This is your app connecting to the remote database.
mysql -uv-token-my-role-vz90z2r03tpx4tq5 -pA1a-z2s3r4wzz568y2uw -h 127.0.0.1

# In the SQL prompt run these commands. Your app has read-only access to this database:
use employees;
desc employees;
select emp_no, first_name, last_name, gender from employees limit 10;

# Log off the database server
exit
```

### Step 6: Revoke the lease
Use the lease id that you generated in step 3. Scroll back in your terminal to find it.
```
vault lease revoke database/creds/my-role/f9cf14cd-806c-50c4-8738-0232129bdd0b

# You can also revoke *all* the leases with this prefix:
vault lease revoke -prefix database/creds/my-role
```

### Step 7: Attempt to log on again
```
mysql -uv-token-my-role-vz90z2r03tpx4tq5 -pA1a-z2s3r4wzz568y2uw -h 127.0.0.1

ERROR 1045 (28000): Access denied for user 'v-token-my-role-vz90z2r03tpx4tq5'@'localhost' (using password: YES)
```

### Optional Stuff

#### Show renewal of a token using renew-self
```
curl -H "X-Vault-Token: $APP_TOKEN" \
     -X POST ${VAULT_ADDR}/v1/auth/token/renew-self | jq
```

#### Show a list of all leases
You can do this in the UI or with this command:
```
vault list /sys/leases/lookup/database/creds/my-role/
```

#### Show a renewal of a lease associated with credentials
The increment is measured in seconds. Try setting it to 86400 and see what happens when you attempt to exceed the max_ttl. Replace with your own lease_id.
```
curl -H "X-Vault-Token: $APP_TOKEN" \
     -X POST \
     --data '{ "lease_id": "database/creds/my-role/1dafdffe-028a-9455-0bde-b6bf1df5e207", "increment": 3600}' \
     ${VAULT_ADDR}/v1/sys/leases/renew | jq .
```

#### Revoke all leases and invalidate all active credentials
```
# Run this five or six times to generate credentials
vault read database/creds/my-role
# Show all the users on the database server
sudo mysql -uroot -pbananas -e 'select user,password from mysql.user;'
# Revoke everything under my-role
vault lease revoke -prefix database/creds/my-role
# Back on the DB server, Voila! users are gone
sudo mysql -uroot -pbananas -e 'select user,password from mysql.user;'
```

#### Enable audit logs
If you want to show off Vault audit logs just run this command:

```
vault audit enable file file_path=/tmp/my-file.txt
```

### Cleanup
```
gcloud compute instances delete mysqlvaultdemo
```
