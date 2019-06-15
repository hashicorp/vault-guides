# Vault Transit Rewrap Record After Key Rotation Example

These assets are provided to perform the tasks described in the [Transit Secret Re-wrapping](https://learn.hashicorp.com/vault/encryption-as-a-service/eaas-transit-rewrap) guide.

---

## Demo Script Guide

The following files are provided as demo scripts:

- `demo_setup.sh` performs [Step 1 through 3](https://learn.hashicorp.com/vault/encryption-as-a-service/eaas-transit-rewrap) in the guide
  * Pull and run mysql server 5.7 docker container
  * Enable transit secret engine
  * Create `my_app_key` encryption key
  * Create `rewrap_example` policy
  * Generate a token to be used by the app
- `run_app.sh` performs [Step 4](https://learn.hashicorp.com/vault/encryption-as-a-service/eaas-transit-rewrap) in the guide
  * Runs the example app
  * Prints out the commends to explore the MySQL DB
- `rewrap_example.sh` performs [Step 5](https://learn.hashicorp.com/vault/encryption-as-a-service/eaas-transit-rewrap) in the guide
  * Read the `my_app_key` details BEFORE the key rotation
  * Rotate the `my_app_key` encryption key
  * Read the `my_app_key` details AFTER the key rotation
  * Prints out the command to set the `min_decryption_version`
- `cleanup.sh` re-set your environment


### Demo Workflow

> **NOTE:** DON'T FORGET that this demo requires [.NET Core and Docker](https://learn.hashicorp.com/vault/encryption-as-a-service/eaas-transit-rewrap) to run the sample app.

1. Run `demo_setup.sh`

2. Run `run_app.sh`
  - Open another terminal
  - Copy and paste the suggested commands to explorer the `user_data` table in mysql

3. Run `rewrap_example.sh` a couple of times and review the key version

4. Run `run_app.sh` again
  - See the data in the `user_data` table are now rewrapped with the _latest_ encryption key version

To demonstrate the minimum key version restriction feature, repeat #3 and then run the commands suggested in the output (`vault write transit/keys/my_app_key/config min_decryption_version=3`). And then, repeat #4.

Finally, run `cleanup.sh` to re-set your environment so that you can repeat the demo as necessary.

> **WARNING:** The `cleanup.sh` disables the transit secret engine. All encryption keys will be deleted. If you are working against a shared Vault server, you might want to ***manually*** clean up the environment instead.
