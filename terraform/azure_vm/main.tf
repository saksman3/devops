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
output "tls_private_key" {
    value = tls_private_key.MyTFssh.private_key_pem 
    sensitive = true
}
output "public_ip" {
 value = azurerm_public_ip.MyTFPublicIP.*.ip_address
}
resource "azurerm_network_security_group" "myTFNetSec" {
  name ="SecurityGroup"
  location = azurerm_resource_group.myTFResourceGroup.location
  resource_group_name = azurerm_resource_group.myTFResourceGroup.name 
}

resource "azurerm_network_security_rule" "myTFSecRule" {
  name                        = "myTFSecRule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "22"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myTFResourceGroup.name
  network_security_group_name = azurerm_network_security_group.myTFNetSec.name
}


resource "azurerm_linux_virtual_machine" "myTFLinuxVM" {
  count = 2
  name                = "myTFLinuxVM${count.index}"
  resource_group_name = azurerm_resource_group.myTFResourceGroup.name
  location            = azurerm_resource_group.myTFResourceGroup.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Asd1!2@2"
  disable_password_authentication =false
  network_interface_ids = [element(azurerm_network_interface.MyTFNetInterface.*.id, count.index)  ]

  


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
#resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_schedule" {
#  count =2
#  virtual_machine_id = azurerm_linux_virtual_machine.myTFLinuxVM${count.index}.id
#  location           = azurerm_resource_group.myTFResourceGroup.location
#  enabled            = true

#  daily_recurrence_time = "1100"
#  timezone              = "South Africa Standard Time"

#  notification_settings {
#    enabled         = true
#    time_in_minutes = "60"
#    webhook_url     = "https://sample-webhook-url.example.com"
#  }
#}
