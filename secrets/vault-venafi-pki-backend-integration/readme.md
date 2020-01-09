# Vault Integration Patterns with Venafi
This guide, along with its corresponding blog details the integration between Vault and Venafi using the vault-pki-backend-venafi plugin

## Reference Material
This code corresponds to a blog published on medium - Vault Integration Patterns with Venafi https://medium.com/@jgerson/vault-integration-patterns-with-venafi-part-2-ff6a5fcc3d3d?sk=96087ff35a3792686966454888e421b9

## Estimated Time to Complete
This guide should take 30 minutes. 

## Prerequisites
Venafi Trust Protection Platform
HashiCorp Vault

This guide will offer a script for running Vault locally for testing. When deploying to production it is recommended to follow HashiCorp’s deployment guide https://learn.hashicorp.com/vault/operations/ops-deployment-guide. Optionally, an existing Vault development environment may be used.

## Synopsis

The integration options for Vault and Venafi appear in the form of Vault plugins: Venafi Secrets Engine (vault-pki-backend-venafi) and Venafi Monitor Engine (vault-pki-monitor-venafi). In the last blog the vault-pki-monitor-venafi plugin was demonstrated. The pki-monitor plugin for Vault allows Vault issued certificates to be governed by Venafi policy.
Both plugins provide visibility and policy enforcement from the Venafi platform for SSL/TLS certificates that serve as machine identities while providing common Vault APIs to developers requesting certificates. To help you determine which plugin is appropriate, here is a brief overview of the benefits of each plugin.

The vault-pki-backend-venafi plugin should be considered when organizations are using cloud deployments as an extension of their datacenter. This will typically look like IaaS services coupled to existing datacenters with VPN connections that may be unidirectional or bidirectional. This will allow organizations to use their existing internal PKI and continue to trust the existing machine identities. The vault-pki-backend-venafi plugin enables developers to obtain both publicly trusted and private SSL/TLS certificates through any of Venafi's Certificate Authority integrations like DigiCert, Entrust, Microsoft, etc. using native Vault commands.

The vault-pki-monitor-venafi plugin should be considered when running in a cloud environment that has limited access to existing corporate data centers when cloud environments need to operate in a disconnected or isolated way. This will typically require the use of a new issuing authority (as described in the previous blog) that will limit trust between cloud resources and on-premise resources. The plugin monitors Vault issued certificates when Vault operates as an intermediate or root CA and enables PKI policy (e.g., allowed values of each field on the certificate, like common_name, organization, etc.) to be centrally defined in Venafi, downloaded to Vault during plugin setup, and enforced during the certificate generation request. This plugin should be considered when high speed issuance is a major design consideration.

The focus of this blog is to demonstrate the vault-pki-backend-venafi for Vault which allows certificate requests to be fulfilled directly by Venafi on behalf of 40+ certificate authorities (CA's). This provides seamless access to publicly-trusted and private SSL/TLS certificates using native Vault commands. In this model, Vault provides the common API for DevOps teams to perform certificate requests, while the Venafi platform fulfills the request. Security teams maintain constant visibility and policy enforcement through Venafi.

Additional details about the workflows between Vault and Venafi can be found in this whitepaper https://www.hashicorp.com/resources/protecting-machine-identities-blueprint-for-the-cloud-operating-model. The previous blog https://medium.com/hashicorp-engineering/vault-integration-patterns-with-venafi-21c3626cdcdb may be referenced if the use case you are looking for requires the vault-pki-monitor-venafi plugin.

Please note there are some pre-requisite Venafi setups explained in the blog post prior to 5_configure_plugin.sh

## Scripts 
Scripts were validated on ubuntu 16.04 and may require adjustments if running on other platforms. 

### Step 1: 1_prepare_plugin.sh - Download and Prepare Plugin
### Step 2: 2_start_over.sh - Kill any running Vault and start Vault (optional)
### Step 3: 3_init_vault.sh - Initialize Vault (optional)
### Step 4: 4_install_plugin.sh - Add Plugin to Vault
### Step 5: 5_init_subca.sh - Enable secrets engine and configure role
### Step 6: 6_test_plugin.sh - Request certificate from Venafi via Vault

