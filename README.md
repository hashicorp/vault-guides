----
-	Website: https://www.vaultproject.io
-  GitHub repository: https://github.com/hashicorp/vault
-	IRC: `#vault-tool` on Freenode
-	Announcement list: [Google Groups](https://groups.google.com/group/hashicorp-announce)
-	Discussion list: [Google Groups](https://groups.google.com/group/vault-tool)

<img width="300" alt="Vault Logo" src="https://cloud.githubusercontent.com/assets/416727/24112835/03b57de4-0d58-11e7-81f5-9056cac5b427.png">

----
# Vault-Guides

This repository aims to assist individuals in learning how to install, configure, and administer HashiCorp Vault.

## Provision

This area will contain instructions to provision Vault (and Consul) as a first step to start using these guides.

These may include use cases installing Vault in cloud services via Terraform, or within virtual environments using Vagrant, or running Vault in a local development mode.

### Guides

- [Provision a Dev Vault Cluster locally with Vagrant](provision/vault-dev/vagrant-local)
- [Provision a Dev Vault Cluster on AWS with Terraform](provision/vault-dev/terraform-aws)
- [Provision a Quick Start Vault & Consul Cluster on AWS with Terraform](provision/vault-quick-start/terraform-aws)
- [Provision a Best Practices Vault & Consul Cluster on AWS with Terraform](provision/vault-best-practices/terraform-aws)

## Secrets

This directory contains example use cases involving [secrets management](https://www.vaultproject.io/docs/secrets/index.html). Secure secret storage of static secrets and sensitive information. Implementation of Dynamic Secrets.

### Guides

None yet, check back soon or feel free to [contribute](CONTRIBUTING.md)!

## Encryption

This directory contains example usage of the [Vault Transit backend](https://www.vaultproject.io/docs/secrets/transit/index.html). Also referred to as 'Encryption as a Service' as it allows organizations to provide a centrally managed encryption service for their infrastructure.

### Guides

None yet, check back soon or feel free to [contribute](CONTRIBUTING.md)!

## PAM

This directory contains examples of privilege access management.

### Guides

None yet, check back soon or feel free to [contribute](CONTRIBUTING.md)!

## IAM

This directory contains examples of identity access management.

### Guides

None yet, check back soon or feel free to [contribute](CONTRIBUTING.md)!

## Shared

This directory contains common scripts and configuration files used to provision environments used for the guides in this repository.

## Assets

This directory contains graphics and other material for the repository.

## Contributing

We welcome contributions and feedback!  For guide submissions, please see [the contributions guide](CONTRIBUTING.md)
