# ---------------------------
# Azure Key Vault
# ---------------------------
variable "tenant_id" {
  default = ""
}

variable "key_name" {
  description = "Azure Key Vault key name"
  default     = "generated-key"
}

variable "location" {
  description = "Azure location where the Key Vault resource to be created"
  default     = "eastus"
}

variable "environment" {
  default = "learn"
}

# ---------------------------
# Virtual Machine
# ---------------------------
variable "public_key" {
  default = ""
}

variable "subscription_id" {
  default = ""
}

variable "client_id" {
  default = ""
}

variable "client_secret" {
  default = ""
}

variable "vm_name" {
  default = "azure-auth-demo-vm"
}

variable "vault_version" {
  # NB execute `apt-cache madison vault` to known the available versions.
  default = "1.9.4"
}

variable "resource_group_name" {
  default = "vault-demo-azure-auth"
}
