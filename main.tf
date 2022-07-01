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
    name                = local.resource_group
  }

  data "azurerm_subnet" "snet" {
    name                 = "iaas-10-201-80-0_24-snet"
    virtual_network_name = "aot-n-zeaus-10-201-80-0_20-vnet" 
    resource_group_name  = local.resource_group
  }

  resource "azurerm_network_interface" "nic" {
    name                = "aotsceptrexlrnictest"
    resource_group_name = local.resource_group
    location            = local.location
  
    ip_configuration {
      name                          = "internal"
      subnet_id                     = data.azurerm_subnet.snet.id
      private_ip_address_allocation = "Dynamic"
    }
  }

  resource "azurerm_virtual_machine" "windows" {
    name                  = "aotsceptrexlrtest"
    resource_group_name   = local.resource_group
    location            = local.location
    vm_size               = "Standard D4ds v5"
    network_interface_ids = [azurerm_network_interface.nic.id]
  
    storage_image_reference {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter-Core-smalldisk"
      version   = "latest"
    }
  
    storage_os_disk {
      name              = "aotsceptrexlrtest_OS_Disk"
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = "Standard_LRS"
      os_type           = "Windows"
	  disk_size_gb      = 127
    }
	
  resource "azurerm_managed_disk" "data_disk" {
    name                 = "aotsceptrexlrtest_DataDisk_0"
	location             = local.location
    resource_group_name  = local.resource_group
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = 128
  }
  
  resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
	managed_disk_id    = azurerm_managed_disk.data_disk.id
	virtual_machine_id = azurerm_windows_virtual_machine.aotsceptrexlrtest.id
	lun                = "0"
	caching            = "ReadWrite"
	depends_on = [
    azurerm_windows_virtual_machine.aotsceptrexlrtest,
    azurerm_managed_disk.data_disk
  ]
  }
  
  resource "azurerm_network_security_group" "vpsx_nsg" {
	name                = "vpsx-nsg"
	location            = local.location
	resource_group_name = local.resource_group


  security_rule {
    name                       = "Allow_HTTP"
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

  resource "azurerm_subnet_network_security_group_association" "nsg_association" {
	subnet_id                 = data.azurerm_subnet.snet.id
	network_security_group_id = azurerm_network_security_group.vpsx_nsg.id
	depends_on = [
		azurerm_network_security_group.vpsx_nsg
	]
  }
    os_profile {
      computer_name  = "aotsceptreprtntest-${count.index}"
      adminUsername: "aotsceptreprtadm"    
	  adminPassword: "Password1234!"
    }
  
    os_profile_windows_config {}
  }