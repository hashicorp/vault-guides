provider "azurerm" {
}

resource "azurerm_resource_group" "tf_rg" {
    name     = "${var.resource_group_name}"
    location = "eastus"

    tags {
        environment = "${var.resource_group_name}"
    }
}

resource "azurerm_virtual_network" "tf_network" {
    name                = "network-${random_id.tf_random_id.hex}"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.tf_rg.name}"

    tags {
        environment = "${random_id.tf_random_id.hex}"
    }
}

resource "azurerm_subnet" "tf_subnet" {
    name                 = "subnet-${random_id.tf_random_id.hex}"
    resource_group_name  = "${azurerm_resource_group.tf_rg.name}"
    virtual_network_name = "${azurerm_virtual_network.tf_network.name}"
    address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "tf_publicip" {
    name                         = "ip-${random_id.tf_random_id.hex}"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.tf_rg.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "${random_id.tf_random_id.hex}"
    }
}

resource "azurerm_network_security_group" "tf_nsg" {
    name                = "nsg-${random_id.tf_random_id.hex}"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.tf_rg.name}"

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

    tags {
        environment = "${random_id.tf_random_id.hex}"
    }
}

resource "azurerm_network_interface" "tf_nic" {
    name                      = "nic-${random_id.tf_random_id.hex}"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.tf_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.tf_nsg.id}"

    ip_configuration {
        name                          = "nic-${random_id.tf_random_id.hex}"
        subnet_id                     = "${azurerm_subnet.tf_subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.tf_publicip.id}"
    }

    tags {
        environment = "${random_id.tf_random_id.hex}"
    }
}

resource "random_id" "tf_random_id" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.tf_rg.name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "tf_storageaccount" {
    name                        = "sa${random_id.tf_random_id.hex}"
    resource_group_name         = "${azurerm_resource_group.tf_rg.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "${random_id.tf_random_id.hex}"
    }
}

data "template_file" "setup" {
  template = "${file("${path.module}/setup.tpl")}"

  vars = {
    resource_group_name = "${var.resource_group_name}"
    vm_name = "${var.vm_name}"
    vault_download_url = "${var.vault_download_url}"
    tenant_id = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    client_id = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "tf_vm" {
    name                  = "${var.vm_name}"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.tf_rg.name}"
    network_interface_ids = ["${azurerm_network_interface.tf_nic.id}"]
    vm_size               = "Standard_DS1_v2"
    
    identity = {
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
        computer_name  = "${var.vm_name}"
        admin_username = "azureuser"
        custom_data = "${data.template_file.setup.rendered}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${var.public_key}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.tf_storageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "${random_id.tf_random_id.hex}"
    }
}