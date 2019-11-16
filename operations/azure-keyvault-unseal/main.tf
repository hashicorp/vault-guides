provider "azurerm" {
}

resource "azurerm_resource_group" "vault" {
  name     = "${var.environment}-vault-rg"
  location = var.location

  tags = {
    environment = "${var.environment}"
  }
}

resource "random_id" "keyvault" {
  byte_length = 4
}

data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "vault" {
  name                        = "${var.environment}-vault-${random_id.keyvault.hex}"
  location                    = azurerm_resource_group.vault.location
  resource_group_name         = azurerm_resource_group.vault.name
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id

  sku_name = "standard"

  tags = {
    environment = "${var.environment}"
  }

  access_policy {
    tenant_id = var.tenant_id

    #object_id = "${var.object_id}"
    object_id = data.azurerm_client_config.current.service_principal_object_id

    key_permissions = [
      "get",
      "list",
      "create",
      "delete",
      "update",
      "wrapKey",
      "unwrapKey",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_key" "generated" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.vault.id
  key_type     = "RSA"
  key_size     = 2048

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
  address_prefix       = "10.0.1.0/24"
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
  network_security_group_id = azurerm_network_security_group.tf_nsg.id

  ip_configuration {
    name                          = "nic-${random_id.keyvault.hex}"
    subnet_id                     = azurerm_subnet.tf_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_publicip.id
  }

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

resource "random_id" "tf_random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.vault.name}"
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
  template = "${file("${path.module}/setup.tpl")}"

  vars = {
    resource_group_name = "${var.environment}-vault-rg"
    vm_name             = "${var.vm_name}"
    vault_download_url  = "${var.vault_download_url}"
    tenant_id           = "${var.tenant_id}"
    subscription_id     = "${var.subscription_id}"
    client_id           = "${var.client_id}"
    client_secret       = "${var.client_secret}"
    vault_name          = "${azurerm_key_vault.vault.name}"
    key_name            = "${var.key_name}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "tf_vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.vault.name
  network_interface_ids = ["${azurerm_network_interface.tf_nic.id}"]
  vm_size               = "Standard_DS1_v2"

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name              = "OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.vm_name
    admin_username = "azureuser"
    custom_data    = base64encode("${data.template_file.setup.rendered}")
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = var.public_key
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.tf_storageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "${var.environment}-${random_id.keyvault.hex}"
  }
}

data "azurerm_public_ip" "tf_publicip" {
  name                = "${azurerm_public_ip.tf_publicip.name}"
  resource_group_name = "${azurerm_virtual_machine.tf_vm.resource_group_name}"
}

output "ip" {
  value = "${data.azurerm_public_ip.tf_publicip.ip_address}"
}

output "ssh-addr" {
  value = <<SSH

    Connect to your virtual machine via SSH:

    $ ssh azureuser@${data.azurerm_public_ip.tf_publicip.ip_address}


SSH

}
