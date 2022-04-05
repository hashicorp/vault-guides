----
-	Website: https://www.vaultproject.io
-	GitHub repository: https://github.com/hashicorp/vault
-	Announcement list: [Google Groups](https://groups.google.com/group/hashicorp-announce)
-	Discussion list: [Google Groups](https://groups.google.com/group/vault-tool)

<img width="300" alt="Vault Logo" src="https://cloud.githubusercontent.com/assets/416727/24112835/03b57de4-0d58-11e7-81f5-9056cac5b427.png">

----
# Vault-Guides

This repository provides the technical content to support the [Vault learn](https://learn.hashicorp.com/vault/) site.

## Operations

This area will contain instructions to operationalize Vault.

- [Provision a Dev Vault Cluster locally with Vagrant](operations/provision-vault/dev/vagrant-local)
- [Provision a Dev Vault Cluster on AWS with Terraform](operations/provision-vault/dev/terraform-aws)
- [Provision a Quick Start Vault & Consul Cluster on AWS with Terraform](operations/provision-vault/quick-start/terraform-aws)
- [Provision a Best Practices Vault & Consul Cluster on AWS with Terraform](operations/provision-vault/best-practices/terraform-aws)

## Secrets

This directory contains example use cases involving [secrets management](https://www.vaultproject.io/docs/secrets/index.html).

## Identity

This directory contains example use cases involving [identity](https://www.vaultproject.io/docs/auth/index.html).

## Encryption

This directory contains example use cases involving [encryption as a service](https://www.vaultproject.io/docs/secrets/transit/index.html).

## Assets

This directory contains graphics and other material for the repository.

## `gitignore.tf` Files

You may notice some [`gitignore.tf`](operations/provision-consul/best-practices/terraform-aws/gitignore.tf) files in certain directories. `.tf` files that contain the word "gitignore" are ignored by git in the [`.gitignore`](./.gitignore) file.

If you have local Terraform configuration that you want ignored (like Terraform backend configuration), create a new file in the directory (separate from `gitignore.tf`) that contains the word "gitignore" (e.g. `backend.gitignore.tf`) and it won't be picked up as a change.

## Contributing

We welcome contributions and feedback! For guide submissions, please see [the contributions guide](CONTRIBUTING.md)
