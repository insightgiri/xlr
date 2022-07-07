#Terraform Block
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Microsoft Azure Provider block
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_subnet" "snet" {
  name                 = "iaas-10-201-80-0_24-snet"
  virtual_network_name = "aot-n-zeaus-10-201-80-0_20-vnet"
  resource_group_name  = var.resource_group_name
}

resource "azurerm_network_interface" "nic" {
  name                = "aotsceptrexlrnictest"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "windows" {
  name                = "aoxlrtest"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  vm_size             = "Standard_D4_v3"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "aorxlrtest_OS_Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    os_type           = "Windows"
    disk_size_gb      = 127
  }

  os_profile {
    computer_name  = "aoxlrtest"
    admin_username = "aoxlradm"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {}
}
resource "azurerm_managed_disk" "datadisk" {
  name                 = "aoxlr_DataDisk_0"
  location             = var.resource_group_location
  resource_group_name  = var.resource_group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  managed_disk_id    = azurerm_managed_disk.datadisk.id
  virtual_machine_id = azurerm_virtual_machine.windows.id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_network_security_group" "xlrnsg" {
  name                = "xlrnsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "Allow_RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "nsgassociation" {
  subnet_id                 = data.azurerm_subnet.snet.id
  network_security_group_id = azurerm_network_security_group.xlrnsg.id
  depends_on = [
    azurerm_network_security_group.xlrnsg
  ]
}
