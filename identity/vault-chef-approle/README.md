# Vault AppRole With Terraform & Chef Demo

These assets are provided to perform the tasks described in the [Vault AppRole with Terraform and Chef Demo](https://learn.hashicorp.com/vault/identity-access-management/iam-approle-trusted-entities) guide.


----

## Demo Instruction

### Setup - Provisioning

1. Set this location as your working directory
2. Set your AWS credentials as environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
3. Update the `terraform.tfvars.example` file accordingly and rename to `terraform.tfvars`.
4. Provision the AWS cloud resources:
```plaintext
$ terraform init
$ terraform plan
$ terraform apply
```

5. SSH into the EC2 instance (this is your **`mgmt`** server)
6. Run `tail -f /var/log/tf-user-data.log` to see when the initial configuration is complete. When you see `.../var/lib/cloud/instance/scripts/part-001: Complete`, you'll know that initial setup is complete.

**NOTE:** Once the user-data script has completed, you'll see the following subfolders:

| Path                                | Description                            |
|-------------------------------------|----------------------------------------|
| `/home/ubuntu/vault-chef-approle-demo` | root of our project                 |
| `/home/ubuntu/vault-chef-approle-demo/chef` | root of our Chef app; this is where our `knife` configuration is located [`.chef/knife.rb`]  |
| `/home/ubuntu/vault-chef-approle-demo/scripts` | there's a `vault-approle-setup.sh` script located here to help automate the setup of Vault, or you can follow along in the rest of this README to configure Vault manually  |


### AppRole Configuration

Run the `/home/ubuntu/demo_setup.sh` script which performs ***Step 3*** through ***6*** in the [guide](https://learn.hashicorp.com/vault/identity-access-management/iam-approle-trusted-entities).


### Chef Node

1. Open another terminal and set  `identity/vault-chef-approle/terraform-aws/chef-node` to be your working directory

2. Update the `terraform.tfvars.example` file accordingly and rename to `terraform.tfvars`:
    * Update the `vault_address` and `chef_server_address` variables with the IP address of our `mgmt` server
    * Update the `vault_token` variable with the `RoleID` in the `/home/ubuntu/vault-chef-approle-demo/roleid-token.json` file on the `mgmt` server:

    ```plaintext
    $ cat ~/vault-chef-approle-demo/roleid-token.json | jq ".auth.client_token"
    ```

3. Provision the Chef node:
```plaintext
$ terraform init
$ terraform plan
$ terraform apply
```

Terraform will perform the following actions:

- Pull a `RoleID` from our Vault server
- Provision an AWS instance
- Write the `RoleID` to the AWS instance as an environment variable
- Run the Chef provisioner to bootstrap the AWS instance with our Chef Server
- Run our Chef recipe which will install NGINX, perform our AppRole login, get our secrets, and output them to our `index.html` file

Once `terraform apply` completes, it will output the public **IP address** of our new server. Enter the IP address in a web browser to see the output. It should look similar to the following:

```plaintext
Role ID:
f6286b97-246e-9fb4-4d9f-0c9465451851

Secret ID:
72f4b60c-26d0-d947-5026-153943174831

AppRole Token:
d11d81e4-0ba1-fefc-03f8-e5f06793b60d

Read Our Secrets:
{:password=>"$up3r$3cr3t!", :username=>"app-1-user"}
```

This concludes the demo.
