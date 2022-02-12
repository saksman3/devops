terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.96.0"
    }
  }
}


provider "azurerm" {
  features{}
}

resource "azurerm_resource_group" "myTFResourceGroup" {
      name = "myTFResourceGroup"
      location = "eastus"
}
resource "azurerm_virtual_network" "MyTFVnet" {
    name = "MyTFVnet"
    location = azurerm_resource_group.myTFResourceGroup.location
    address_space = ["10.0.0.0/16"]
    resource_group_name = azurerm_resource_group.myTFResourceGroup.name

}
resource "azurerm_subnet" "MyTFSubnet" {
    name = "MyTFSubnet"
    resource_group_name = azurerm_resource_group.myTFResourceGroup.name
    virtual_network_name = azurerm_virtual_network.MyTFVnet.name
    address_prefixes = ["10.0.2.0/24"]
  
}
resource "azurerm_public_ip" "MyTFPublicIP" {
  count = 2
  name                = "MyTFPublicIP${count.index}"
  resource_group_name = azurerm_resource_group.myTFResourceGroup.name
  location            = azurerm_resource_group.myTFResourceGroup.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
  
}

resource "azurerm_network_interface" "MyTFNetInterface" {
  count =2
  name = "MyTFNetInterface${count.index}"
  location = azurerm_resource_group.myTFResourceGroup.location
  resource_group_name = azurerm_resource_group.myTFResourceGroup.name
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.MyTFSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.MyTFPublicIP.*.id, count.index)
  }
}

resource "tls_private_key" "MyTFssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "azurerm_linux_virtual_machine" "myTFLinuxVM" {
  count = 2
  name                = "myTFLinuxVM${count.index}"
  resource_group_name = azurerm_resource_group.myTFResourceGroup.name
  location            = azurerm_resource_group.myTFResourceGroup.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [element(azurerm_network_interface.MyTFNetInterface.*.id, count.index)  ]

  

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.MyTFssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version = "latest" 
   }
}
