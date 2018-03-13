# Vault Transit Rewrap Record After Key Rotation Example
The goal of this guide is to demonstrate one possible way to re-wrap data after rotating an encryption key in the transit engine in Vault.

## Estimated Time to Complete
30 Minutes

## Prerequisites

- [Vault Cluster Guide](https://www.vaultproject.io/guides/vault-cluster.html)
- [Vault Initialization Guide](https://www.vaultproject.io/guides/vault-init.html)
- [.NET Core](https://www.microsoft.com/net/download)
- [Docker](https://docs.docker.com/install/)

## Challenge
Vault's transit engine, sometimes referred to as Encryption As A Service, encrypts data.  Applications can use Vault to encrypt and decrypt sensitive data.  Both small amounts of arbitrary data, and large files such as images, can be protected with the transit engine.  Transit can augment or eliminate the need for TDE with databases, it can encrypt bucket/volume/disk contents, etc.  

One of  the benefits of using EAAS with Vault is the ability to easily rotate keys.  Keys can be rotated by a human, or the process can be automated using cron, a CI pipeline, a periodic Nomad batch job, Kubernetes Job, etc, to interact the key rotation API endpoint.  Each key has a version associated with it.  Vault maintains this versioned keyring, and the operator can decide what the minimum version allowed is for decryption operations.  When data is encrypted using Vault the resultant ciphertext is prepended with the version of key used to encrypt it.  The following example shows data that was encrypted using the fourth version of a particular key:
```
vault:v4:ueizdCqCJ/YhowQSvmJyucnLfIUMd4S/nLTpGTcz64HXoY69dwOrqerFzOlhqg==
```

For example, an organization could decide that a key should be rotated once a week, and that the minimum version allowed to decrypt records is the current version as well as the previous two versions.  If the current version is five, then Vault would decrypt records that were sent to it with the following prefixes:
 - vault:**v5**:lkjasfdlkjafdlkjsdflajsdf==
 - vault:**v4**:asdfas9pirapirteradr33vvv==
 - vault:**v3**:ouoiujarontoiue8987sdjf^1==

In this example what would happen if we sent Vault data encrypted with the first or second version of the key (vault:v1 or vault:v2:asdf==)?  Vault would refuse to decrypt the data as the key used is less than the minimum key version allowed.

Luckily Vault provides an easy way of re-wrapping encrypted data when a key is rotated.  Using the rewrap API endpoint a non-priveleged Vault entity can send data encrypted with an older version of the key to have it re-encrypted with the latest version.  The application performing the re-wrapping never interacts with the decrypted data.  The process of rolling the encryption key and rewrapping records could (and should) be completely automated.  Records could be updated slowly over time to lessen database load, or all at once at the time of rotation.  The exact implementation will depend heavily on the needs of each particular organization or application.

The following application demonstrates one possible way of doing this.

## References

- [Vault Secret Engine](https://www.vaultproject.io/docs/secrets/transit/index.html)
- [Vault Secret Engine API](https://www.vaultproject.io/api/secret/transit/index.html)
- [TDE in the Modern Datacenter](https://www.hashicorp.com/blog/transparent-data-encryption-in-the-modern-datacenter)

## Steps

The following instructions assume you have Vault available on localhost, and are running the database locally using Docker.  These steps would work for an existing Vault installation or an existing mysql database by supplying the proper network information.

Please note that the instructions provided are aimed at Linux.  

### Database
You need a database to test with.  You can create one to test with easily using Docker:

```bash
# Pull the latest mysql container image
docker pull mysql/mysql-server:5.7

# Create a directory for our data (change the following
# line if running on Windows)
mkdir ~/rewrap-data

# Run the container.  The following command creates a
# database named 'my_app', specifies the root user
# password as 'root', and adds a user named vault
docker run --name mysql-rewrap \
  -p 3306:3306 \
  -v ~/rewrap-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_ROOT_HOST=% \
  -e MYSQL_DATABASE=my_app \
  -e MYSQL_USER=vault \
  -e MYSQL_PASSWORD=vaultpw \
  -d mysql/mysql-server:5.7
```

### Vault
To configure Vault (if testing locally):



```bash
# Run the vault server
vault server -dev -dev-root-token-id=root &

# Set the vault address environment variable
export VAULT_ADDR='http://127.0.0.1:8200'

# enable the transit secret engine
vault secrets enable transit

# create an encryption key to use for transit
# named 'my_app_key'
vault write -f transit/keys/my_app_key
```

Please note that the above command runs Vault in dev mode which means that secrets will not be persisted to disk.  If you stop the Vault process you will not be able to read records saved using any keys it created.  You will need to wipe the records from the database, and begin testing with new records.  

Next we need to create a limited scope policy for our application to use.  We will create a policy named 'rewrap-example' that has a very minimal policy:


```
echo 'path "transit/keys/my_app_key" {
  capabilities = ["read"]
}

path "transit/rewrap/my_app_key" {
  capabilities = ["update"]
}

# This last policy is needed to seed the database
# as part of the example.  
# It can be omitted if seeding is not required

path "transit/encrypt/my_app_key" {
  capabilities = ["update"]
}
' | vault policy-write rewrap-example -

```

Finally, create a token to use the policy we just created:

```
vault token-create -policy=rewrap-example
```

### Application
You then need to run the app.  The token, location, and name of the transit key to rewrap are accessed using environment variables.  Be sure to supply the token created in the last step:


```bash
$ VAULT_TOKEN=2616214b-6868-3589-b443-0330d7915882 \
VAULT_ADDR=http://localhost:8200 \
VAULT_TRANSIT_KEY=my_app_key \
SHOULD_SEED_USERS=true \
dotnet run
```

If you need to seed test data you can do so by including the SHOULD_SEED_USERS=true.  

Example output:
```
$ VAULT_TOKEN=$TOKEN VAULT_ADDR=http://localhost:8200 VAULT_TRANSIT_KEY=my_app_key SHOULD_SEED_USERS=true dotnet run
Connecting to Vault server...
Seeded the database...
Moving rewrap...
Current Key Version: 5
Found 0 records to rewrap.
```

You can inspect the contents of the database with:
```bash
docker exec -it mysql-transit mysql -uroot -proot
...
mysql> DESC user_data;
mysql> SELECT * FROM user_data WHERE dob LIKE "vault:v1%" limit 10;
...
```

### Rotate The Keys

The key we created (my_app_key) can be rotated using the web UI, command line, or via API call.  We will use the command line for brevity, and inspect the key information:

```bash
$ vault write -f  transit/keys/my_app_key/rotate
Success! Data written to: transit/keys/my_app_key/rotate
$ vault read transit/keys/my_app_key
Key                   	Value
---                   	-----
deletion_allowed      	false
derived               	false
exportable            	false
keys                  	map[3:1517605847 4:1517606935 5:1517609423 6:1517771648 1:1517432000 2:1517593679]
latest_version        	6
min_decryption_version	4
min_encryption_version	0
name                  	my_app_key
supports_decryption   	true
supports_derivation   	true
supports_encryption   	true
supports_signing      	false
type                  	aes256-gcm96

```

We can see that in the above example the current version of the key is six, and any records encrypted with four or greater can be decrypted.

Let us ensure we use the latest version of the key so we can rewrap our existing records.

```
# replace '5' with the appropriate version
$ echo -n '{"min_decryption_version" : 5}' | vault write transit/keys/my_app_key -

# Verify the changes were successful
$ vault read transit/keys/my_app_key
# look at min_decryption_version
```

Now we have records in the database, and we have updated our minimum key version.  We can run the application again, and should see it update records as appropriate.  Remember you can inspect records using my mysql shell (see above).

```
$ VAULT_TOKEN=2616214b-6868-3589-b443-0330d7915882 VAULT_ADDR=http://localhost:8200 VAULT_TRANSIT_KEY=my_app_key SHOULD_SEED_USERS=true dotnet run
Connecting to Vault server...
Seeded the database...
Current Key Version: 6
Found 3500 records to rewrap.
Wrapped another 10 records: 10 so far...
Wrapped another 10 records: 20 so far...
Wrapped another 10 records: 30 so far...
...
```

#### Validation

The application has now re-wrapped all records with the latest key.  You can verify by running the application again, or by inspecting the records using the mysql client.


### Conclusion

An application similar to this could be scheduled via cron, run periodically as a [Nomad batch job](https://www.nomadproject.io/docs/job-specification/periodic.html), or executed in a variety of other ways.  You could also modify it to re-wrap a limited number of records at a time so as not to put undue strain on the database.  The final implementation should be based upon the needs and design goals specific to each organization or application.  
