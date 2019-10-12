# Declare vars
variable "subscription_id"{}
variable "client_id"{}
variable "client_secret"{}
variable "tenant_id"{}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "tfGroup1" {
    name     = "tfResourceGroup1"
    location = "eastus"

    tags = {
        environment = "tf Dev"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "tfNetwork1" {
    name                = "tfVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.tfGroup1.name}"

    tags = {
        environment = "tf Dev"
    }
}

# Create subnet
resource "azurerm_subnet" "tfSubnet1" {
    name                 = "tfSubnet"
    resource_group_name  = "${azurerm_resource_group.tfGroup1.name}"
    virtual_network_name = "${azurerm_virtual_network.tfNetwork1.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "tfpublicip1" {
    name                         = "tfPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.tfGroup1.name}"
    allocation_method            = "Dynamic"

    tags = {
        environment = "tf Dev"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "tfnsg" {
    name                = "tfNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.tfGroup1.name}"
    
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

    tags = {
        environment = "tf Dev"
    }
}

# Create network interface
resource "azurerm_network_interface" "tfnic" {
    name                      = "tfNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.tfGroup1.name}"
    network_security_group_id = "${azurerm_network_security_group.tfnsg.id}"

    ip_configuration {
        name                          = "tfNicConfiguration"
        subnet_id                     = "${azurerm_subnet.tfSubnet1.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.tfpublicip1.id}"
    }

    tags = {
        environment = "tf Dev"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.tfGroup1.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "tfstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.tfGroup1.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "tf Dev"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "tfvm" {
    name                  = "tfVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.tfGroup1.name}"
    network_interface_ids = ["${azurerm_network_interface.tfnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "tfOsDisk"
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
        computer_name  = "hostname"
        admin_username = "testadmin"
        admin_password = "Password12345!"
    }
    
    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.tfstorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "tf Dev"
    }
}
