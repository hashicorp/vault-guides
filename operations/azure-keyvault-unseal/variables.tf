variable "tenant_id" {
    default = ""
}

variable "location" {
    description = "Azure location where the Key Vault resource to be created"
    default = "eastus"
}

variable "environment" {
    default = "Test"
}
