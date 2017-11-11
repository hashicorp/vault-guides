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

These may include use cases installing Vault in cloud services via Terraform, or within virtual environments using Vagrant, or running Vault in a local development mode.  


## GettingStarted
This area will contain tutorials for people just starting out with Vault.

Topics such as installation, initialization, unsealing, basic operations will be covered in this area. 

The official Vault site also has a [Getting Started](https://www.vaultproject.io/intro/getting-started/install.html) section that provides a good first step towards using Vault. This section will contain similar tutorials.

## EaaS (Encryption as a Service) 
This directory contains example usage of the [Vault Transit backend](https://www.vaultproject.io/docs/secrets/transit/index.html).

## SecretsManagement
This directory contains example use cases involving [secrets management](https://www.vaultproject.io/docs/secrets/index.html). Secure secret storage of static secrets and sensitive information. Implementation of Dynamic Secrets.

## PrivilegeAccessManagement
This directory contains examples of privilege access management.

## shared
This directory contains common scripts and configuration files used to provision environments used for the guides in this repository.


### Contributing
We welcome contributions and feedback!  For guide submissions, please see [the contributions guide](CONTRIBUTING.md)