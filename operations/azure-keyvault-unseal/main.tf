# see https://github.com/hashicorp/terraform
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    template = "~> 2.2.0"
    random = "~> 3.1.2"
    azurerm = "~> 3.24.0"
    azuread = "~> 2.29.0"
  }
}

# see https://github.com/terraform-providers/terraform-provider-azurerm
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "vault" {
  name     = "${var.environment}-vault-rg"
  location = var.location

  tags = {
    environment = var.environment
  }
}

resource "random_id" "keyvault" {
  byte_length = 4
}

data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "vault" {
  application_id = var.client_id
}

resource "azurerm_key_vault" "vault" {
  name                = "${var.environment}-vault-${random_id.keyvault.hex}"
  location            = azurerm_resource_group.vault.location
  resource_group_name = azurerm_resource_group.vault.name
  tenant_id           = var.tenant_id

  # enable virtual machines to access this key vault.
  # NB this identity is used in the example /tmp/azure_auth.sh file.
  #    vault is actually using the vault service principal.
  enabled_for_deployment = true

  sku_name = "standard"

  tags = {
    environment = var.environment
  }

  # access policy for the hashicorp vault service principal.
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azuread_service_principal.vault.object_id

    key_permissions = [
      "Get",
      "WrapKey",
      "UnwrapKey",
    ]
  }

  # access policy for the user that is currently running terraform.
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
    ]
  }

  # TODO does this really need to be so broad? can it be limited to the vault vm?
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# TODO the "generated" resource name is not very descriptive; why not use "vault" instead?
# hashicorp vault will use this azurerm_key_vault_key to wrap/encrypt its master key.
resource "azurerm_key_vault_key" "generated" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "wrapKey",
    "unwrapKey",
  ]
}

output "key_vault_name" {
  value = azurerm_key_vault.vault.name
}

# ---------------------
# Create Vault VM
# ---------------------
resource "azurerm_virtual_network" "tf_network" {
  name                = "network-${random_id.keyvault.hex}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

resource "azurerm_subnet" "tf_subnet" {
  name                 = "subnet-${random_id.keyvault.hex}"
  resource_group_name  = azurerm_resource_group.vault.name
  virtual_network_name = azurerm_virtual_network.tf_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "tf_publicip" {
  name                = "ip-${random_id.keyvault.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

resource "azurerm_network_security_group" "tf_nsg" {
  name                = "nsg-${random_id.keyvault.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Vault"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

resource "azurerm_network_interface" "tf_nic" {
  name                      = "nic-${random_id.keyvault.hex}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.vault.name

  ip_configuration {
    name                          = "nic-${random_id.keyvault.hex}"
    subnet_id                     = azurerm_subnet.tf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_publicip.id
  }

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

resource "azurerm_network_interface_security_group_association" "tf_nisga" {
  network_interface_id      = azurerm_network_interface.tf_nic.id
  network_security_group_id = azurerm_network_security_group.tf_nsg.id
}

resource "random_id" "tf_random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.vault.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "tf_storageaccount" {
  name                     = "sa${random_id.keyvault.hex}"
  resource_group_name      = azurerm_resource_group.vault.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

data "template_file" "setup" {
  template = file("${path.module}/setup.tpl")

  vars = {
    resource_group_name = "${var.environment}-vault-rg"
    vm_name             = var.vm_name
    vault_version       = var.vault_version
    tenant_id           = var.tenant_id
    subscription_id     = var.subscription_id
    client_id           = var.client_id
    client_secret       = var.client_secret
    vault_name          = azurerm_key_vault.vault.name
    key_name            = var.key_name
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "tf_vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.vault.name
  network_interface_ids = [azurerm_network_interface.tf_nic.id]
  size                  = "Standard_DS1_v2"
  custom_data           = base64encode(data.template_file.setup.rendered)
  computer_name         = var.vm_name
  admin_username        = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.public_key
  }

  # NB this identity is used in the example /tmp/azure_auth.sh file.
  #    vault is actually using the vault service principal.
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "${var.vm_name}-os"
    caching              = "ReadWrite" # TODO is this safe?
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.tf_storageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

data "azurerm_public_ip" "tf_publicip" {
  name                = azurerm_public_ip.tf_publicip.name
  resource_group_name = azurerm_linux_virtual_machine.tf_vm.resource_group_name
}

output "ip" {
  value = data.azurerm_public_ip.tf_publicip.ip_address
}

output "ssh-addr" {
  value = <<SSH

    Connect to your virtual machine via SSH:

    $ ssh azureuser@${data.azurerm_public_ip.tf_publicip.ip_address}


SSH
}
