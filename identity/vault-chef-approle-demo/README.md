Work in progress...

# Vault AppRole Example(s)

This demo is **_NOT SUITABLE FOR PRODUCTION USE!!_**

This project is a working implementation of the concepts discussed in the _"Secure Introduction with Vault: AppRole + Chef" (link TBD)_ Guide/Blogpost. It aims to provide an end-to-end example of how to use Vault's [AppRole authentication backend](https://www.vaultproject.io/docs/auth/approle.html), along with Terraform & Chef, to address the challenge of _secure introduction_ of an initial token to a target server/application.

This project contains the following assets:
- Chef cookbook [`/chef`]: A sample cookbook with a recipe that installs Nginx and demonstrates Vault Ruby Gem functionality used to interact with Vault APIs.
- Terraform configurations [`/terraform`]:
    - `/terraform/mgmt-node`: Configuration to set up a management server running both Vault and Chef Server, for demo purposes.
    - `/terraform/chef-node`: Configuration to set up a Chef node and bootstrap it with the Chef Server, passing in Vault's AppRole RoleID and the appropriate Chef run-list.
- Vault configuration [`/vault`]: Data used to configure the appropriate mounts and policies in Vault for this demo.

References:
- [Jeff Mitchell: Managing Secrets in a Container Environment](https://www.youtube.com/watch?v=skENC9aXgco)
- [Seth Vargo: Using HashiCorp's Vault with Chef](https://www.hashicorp.com/blog/using-hashicorps-vault-with-chef)
- [Seth Vargo & JJ Asghar: Manage Secrets with Chef and HashiCorps Vault](https://blog.chef.io/2016/12/12/manage-secrets-with-chef-and-hashicorps-vault/)
    - [Associated Github repo](https://github.com/sethvargo/vault-chef-webinar)
- [Alan Thatcher: Vault AppRole Authentication](http://blog.alanthatcher.io/vault-approle-authentication/)
- [Alan Thatcher: Integrating Chef and HashiCorp Vault](http://blog.alanthatcher.io/integrating-chef-and-hashicorp-vault/)
- [Vault Ruby Client](https://github.com/hashicorp/vault-ruby)
- https://github.com/hashicorp-guides/vault-approle-chef (will eventually be merged with this repo)

## Provisioning Steps

Provisioning for this project happens in 2 phases:

1. Vault + Chef Server
2. Chef node (target system to which RoleID and SecretID are delivered)

### Phase 1: Vault + Chef Server [`/terraform/mgmt-node`]

This provides a quick and simple Vault and Chef Server configuration to help you get started.
- In other words, this demo is **_NOT SUITABLE FOR PRODUCTION USE!!_**

In this phase, we use Terraform to spin up a server (and associated AWS resources) with both Vault and Chef Server installed. Once this server is up and running, we'll complete the appropriate configuration steps in Vault and get our Chef admin key that will be used to bootstrap our Chef node (phase 2).

_If using [Terraform Enterprise](https://www.terraform.io/docs/enterprise/getting-started/index.html), create a Workspace for this repo and set the appropriate Terraform/Environment variables using the `terraform.tfvars.example` file as a reference. Follow the instructions in the documentation linked above to perform the appropriate setup in Terraform Enterprise._

Using Terraform Open Source:

1. After cloning this repo, `cd` into the `vault-chef-approle-demo/terraform/mgmt-node` directory.
2. Make sure to update the `terraform.tfvars.example` file accordingly and rename to `terraform.tfvars`.
3. Perform a `terraform plan` to verify your changes and the resources that will be created. If all looks good, then perform a `terraform apply` to provision the resources.
    - The Terraform output will display the public IP address to SSH into your server.
4. Once you can access your Vault + Chef server, run `tail -f /var/log/tf-user-data.log` to see when the initial configuration is complete. This might take several minutes since we're setting everything up from scratch. Once done, you'll see that we performed a `git clone` of this repository in order to pull down the appropriate Chef cookbook(s) and Vault configurations:
    - `/home/ubuntu/vault-chef-approle-demo`: root of our Git repo.
    - `/home/ubuntu/vault-chef-approle-demo/chef`: root of our Chef app. This is where our `knife` configuration is located [`.chef/knife.rb`].
    - `/home/ubuntu/vault-chef-approle-demo/vault`: root of our Vault configurations. There's a `scripts/provision.sh` script to automate the provisioning, or you can follow along in the guide (linked above) to configure Vault manually.
5. Perform initial Vault configuration: `cd` to `/home/ubuntu/vault-chef-approle-demo/vault/scripts` and run the `provision.sh` script.

Work in progress...
