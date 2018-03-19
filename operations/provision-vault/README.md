# Provision Vault

The goal of this guide is to allows users to easily provision a Vault cluster in just a few short commands.

## Reference Material

- [Terraform](https://www.terraform.io/)
- [Consul](https://www.consul.io/)
- [Vault](https://www.vaultproject.io/)

## Estimated Time to Complete

5 minutes.

## Personas

### Operator

The operator is responsible for producing the Vault cluster infrastructure and managing day 1 & 2 operations. This includes initial service administration, upgrades, logging/monitoring, and more.

### Developer

The developer will be consuming the Vault services and developing against it. This may be leveraging Vault for Secrets Management, Identity, and Encryption as a Service.

### InfoSec

Infosec will be creating and managing ACLs for Vault, this may include both ACLs and Sentinel policies.

## Challenge

There are many different ways to provision and configure a Vault cluster, making it difficult to get started.

## Solution

Provision a Vault cluster. This will enable users to easily provision a Vault cluster for their desired use case.

### Dev

The [Vault Dev Guides](./dev) are for **educational purposes only**. They're designed to allow you to quickly standup a single instance with Vault running in `-dev` mode in your desired provider. The single node is provisioned into a single public subnet that's completely open, allowing for easy (and insecure) access to the instance. Because Vault is running in `-dev` mode, all data is in-memory and not persisted to disk. If any agent fails or the node restarts, all data will be lost. This is in no way, shape, or form meant for Production use, please use with caution.

### Quick Start

The [Vault Quick Start Guide](./quick-start) provisions a 3 node Vault cluster and 3 node Consul cluster with all agents running in server mode in the provider of your choice.

The Quick Start guide leverages the scripts in the [Guides Configuration Repo](https://github.com/hashicorp/guides-configuration) to do runtime configuration of Vault. Although using `curl bash` at runtime is _not_ best practices, this makes it quick and easy to standup a Vault cluster with no external dependencies like pre-built images. This guide will also forgo setting up TLS/encryption on Vault for the sake of simplicity.

### Best Practices

The [Vault Best Practices Guide](./best-practices) provisions a 3 node Vault cluster with a similar architecture to the [Quick Start](#quick-start) guide in the provider of your choice. The difference is this guide will setup TLS/encryption across Vault and depends on pre-built images rather than runtime configuration. You can find the Packer templates to create these Vault images in the [Guides Configuration Repo](https://github.com/hashicorp/guides-configuration/tree/master/vault).

## Steps

We will now provision the Vault cluster.

### Step 1: Choose your Preferred Guide

`cd` into one of the below guides from the root of the repository and follow the instructions from there.

- [Vagrant dev](./dev/vagrant-local)
- [AWS dev](./dev/terraform-aws)
- [AWS quick-start](./quick-start/terraform-aws)
- [AWS best-practices](./best-practices/terraform-aws)

#### CLI

```sh
$ cd operations/provision-vault/dev/vagrant-local
$ cd operations/provision-vault/dev/terraform-aws
$ cd operations/provision-vault/quick-start/terraform-aws
$ cd operations/provision-vault/best-practices/terraform-aws
```

## Next Steps

Now that you've provisioned and configured Vault, start walking through the [Vault Guides](https://www.vaultproject.io/guides/index.html).
