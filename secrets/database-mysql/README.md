# Generating dynamic MySQL credentials using Vault Database backend

This guide describes the commands to configure Vault to generate dynamic database credentials. Vault and MySQL are installed in a local machine using Vagrant.

## Reference Material
Complete documentation of the Vaulta database secret engine can be found here:
https://www.vaultproject.io/docs/secrets/databases/index.html

## Estimated Time to Complete
10 minutes

## Personas
In an enterprise setting, the Vault admin will potentially need assistance from the DBA which will be responsible for:
- Provide a template SQL query for generating the dynamic users. In this query the user privileges within the database will be defined, i.e. access to which tables.
- Create a Vault username and password in the database, with sufficient privileges to run the above query.

## Challenge
Traditionally in enterprise settings, developers need to open a ticket to the DBA whenever they need a new user account created in the database. They are then responsible for managing the rotation of these passwords. This approach is not ideal for a few reasons:
- It does not scale well, since for every new account request, the DBA must create new credentials
- Password rotation provide limited security protection, and might rely on manual intervention
- It does now allow independent access for instances sharing same profile. For example 3 instances of a web server might share the same credentials. If there is a compromise and these credentials need to be revoked, all web servers will stop working
- Unused credentials might sit iddle for indeterminate ammount of time, exposing the DB to threats

## Solution
Dynamic DB credentials solve the above challenges by:
- Automating the creation process, 
- Assigning a TTL (time to live) to these credentials which at the end revokes and deletes the credentials from the database, 
- Allowing multiple credentials for the same set of permissions (role).

## Prerequisites
- The sample code in this repository is self-contained, only requiring Vagrant and a virtual machine provider to be installed in the machine. More information at: https://www.vagrantup.com/downloads.html

## Steps
The bellow steps should be executed in a terminal once this repository is cloned

### Step 1: Run virtual machine
```
# This will install and run Vault in dev mode
cd secrets/database_mysql/vagrant-local
vagrant up
```

### Step 2: Install MySQL and configure Vault
```
# This will install, run and configure MySQL, and configure Vault to use the dynamic database credentials functionality
vagrant ssh
cd /vagrant
./database_mysql_setup.sh
```

### Step 3: Generate dynamic credentials
```
vault read database/creds/readonly
```

#### Output:
```
Key            	Value
---            	-----
lease_id       	database/creds/readonly/e9fff0f7-64f7-eff5-22bb-1fbd9d0781b4
lease_duration 	30m
lease_renewable	true
password       	A1a-4488p19t14v97tyv
username       	v-read-u3w83xy3u
```

### Step 4: Validate the new user exists in the database
```
mysql -u root -p'R00tPassword' -e "select user from mysql.user;"
```

#### Output:
```
+------------------+
| user             |
+------------------+
| v-read-u3w83xy3u |
| root             |
| vaultadmin       |
|                  |
+------------------+
```