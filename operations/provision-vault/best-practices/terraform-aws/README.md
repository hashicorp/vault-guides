# Provision a Best Practices Vault Cluster in AWS

The goal of this guide is to allow users to easily provision a best practices Vault & Consul cluster in just a few commands.

## Reference Material

- [Terraform Getting Started](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Terraform Docs](https://www.terraform.io/docs/index.html)
- [Consul Getting Started](https://www.consul.io/intro/getting-started/install.html)
- [Consul Docs](https://www.consul.io/docs/index.html)
- [Vault Getting Started](https://learn.hashicorp.com/vault/getting-started/install)
- [Vault Docs](https://www.vaultproject.io/docs/index.html)

## Estimated Time to Complete

5 minutes.

## Challenge

There are many different ways to provision and configure an easily accessible best practices Vault & Consul cluster, making it difficult to get started.

## Solution

Provision a best practices Vault & Consul cluster in a private network with a bastion host.

The AWS Best Practices Vault guide provisions a 3 node Vault and 3 node Consul cluster with a similar architecture to the [Quick Start](../../quick-start) guide. The difference is this guide will setup TLS/encryption across Vault & Consul and depends on pre-built images rather than runtime configuration. You can find the Packer templates to create the [Consul image](https://github.com/hashicorp/guides-configuration/blob/master/consul/consul-aws.json) and [Vault image](https://github.com/hashicorp/guides-configuration/blob/master/vault/vault-aws.json) in the [Guides Configuration Repo](https://github.com/hashicorp/guides-configuration/).

## Prerequisites

- [Download Terraform](https://www.terraform.io/downloads.html)

## Steps

We will now provision the best practices Vault cluster.

### Step 1: Initialize

Initialize Terraform - download providers and modules.

#### CLI

[`terraform init` Command](https://www.terraform.io/docs/commands/init.html)

##### Request

```sh
$ terraform init
```

##### Response
```
Initializing modules...
- module.ssh_keypair_aws_override
  Getting source "github.com/hashicorp-modules/ssh-keypair-aws"
- module.consul_auto_join_instance_role
  Getting source "github.com/hashicorp-modules/consul-auto-join-instance-role-aws"
  [...]
  [...]

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "aws" (2.8.0)...
  [...]
  [...]

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.8"
* provider.null: version = "~> 2.1"
* provider.random: version = "~> 2.1"
* provider.template: version = "~> 2.1"
* provider.tls: version = "~> 2.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Step 2: Plan

Run a `terraform plan` to ensure Terraform will provision what you expect.

#### CLI

[`terraform plan` Command](https://www.terraform.io/docs/commands/plan.html)

##### Request

```sh
$ terraform plan
```

##### Response
```
provider.aws.region
  The region where AWS operations will take place. Examples
  are us-east-1, us-west-2, etc.

  Default: us-east-1
  Enter a value: us-east-1

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.aws_iam_policy_document.assume_role: Refreshing state...
data.aws_elb_service_account.vault_lb_access_logs: Refreshing state...
[...]
[...]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

<--- more here --->


Plan: 127 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

### Step 3: Apply

Run a `terraform apply` to provision the HashiStack. One provisioned, view the `zREADME` instructions output from Terraform for next steps.

#### CLI

[`terraform apply` command](https://www.terraform.io/docs/commands/apply.html)

##### Request

```sh
$ terraform apply
```

##### Response
```
```

## Next Steps

Now that you've provisioned and configured a best practices Vault & Consul cluster, visit our [learn](https://learn.hashicorp.com/vault/?track=secrets-management#secrets-managemen) site.
