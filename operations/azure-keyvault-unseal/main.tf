provider "azurerm" {}

resource "azurerm_resource_group" "vault" {
  name     = "${var.environment}-vault-rg"
  location = "${var.location}"
}

resource "random_id" "keyvault" {
  byte_length = 4
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                        = "${var.environment}-vault-${random_id.keyvault.hex}"
  location                    = "${azurerm_resource_group.vault.location}"
  resource_group_name         = "${azurerm_resource_group.vault.name}"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${var.tenant_id}"

  sku {
    name = "standard"
  }

  tags {
    environment = "${var.environment}"
  }

  access_policy {
    tenant_id = "${var.tenant_id}"
    #object_id = "${var.object_id}"
    object_id = "${data.azurerm_client_config.current.service_principal_object_id}"

    certificate_permissions = [
      "get",
      "list",
      "create",
      "delete",
      "update",
    ]

    key_permissions = [
      "get",
      "list",
      "create",
      "delete",
      "update",
      "wrapKey",
      "unwrapKey",
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}


resource "azurerm_key_vault_key" "generated" {
  name      = "generated-key"
  vault_uri = "${azurerm_key_vault.vault.vault_uri}"
  key_type  = "RSA"
  key_size  = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

output "key_vault_name" {
  value = "${azurerm_key_vault.vault.name}"
}
