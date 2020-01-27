# Vault Integration Patterns with Venafi Cloud
This guide, along with its corresponding blog details the integration between Vault and Venafi using the vault-pki-backend-venafi plugin

## Reference Material
This code corresponds to a blog published on medium - Vault Integration Patterns with Venafi Cloud

## Estimated Time to Complete
This guide should take 30 minutes. 

## Prerequisites
Venafi Cloud Account with admin access
HashiCorp Vault

This guide will offer a script for running Vault locally for testing. When deploying to production it is recommended to follow HashiCorp’s deployment guide https://learn.hashicorp.com/vault/operations/ops-deployment-guide. Optionally, an existing Vault development environment may be used.

## Synopsis

This blog is the first part of a series that explores the integration methods currently available between Vault and Venafi Cloud.

The integration options for Vault and Venafi appear in the form of Vault plugins: Venafi Secrets Engine (vault-pki-backend-venafi) and Venafi Monitor Engine (vault-pki-monitor-venafi). Vault integrates with the Venafi Platform (see blog 1 and blog 2) and Venafi Cloud for DevOps. 

The Venafi Platform is well suited for organizations that need enterprise scalability, workflow and integrations options across on-premises and the cloud. Venafi Cloud for DevOps is Venafi's new SaaS offering that allows DevOps teams to quickly obtain policy compliant certificates from your organization's approved CA without requiring you to install/manage software.

This post explores using the vault-pki-backend-venafi with Venafi Cloud for DevOps, which serves the targeted use case of connecting trusted third-party certificate authorities to Vault, enabling developers to use native Vault commands to request certificates from leading CAs such as GlobalSign and DigiCert.

Please note there are some pre-requisite Venafi setups explained in the blog post prior to 5_configure_plugin.sh

## Scripts 
Scripts were validated on ubuntu 16.04 and may require adjustments if running on other platforms. 

### Step 1: 1_prepare_plugin.sh - Download and Prepare Plugin
### Step 2: 2_start_over.sh - Kill any running Vault and start Vault (optional)
### Step 3: 3_init_vault.sh - Initialize Vault (optional)
### Step 4: 4_install_plugin.sh - Add Plugin to Vault
### Step 5: 5_configure_plugin.sh - Enable secrets engine and configure role
### Step 6: 6_test_plugin.sh - Request certificate from Venafi via Vault