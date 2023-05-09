locals {
  vm_specifications_win = {
    vm-test-win-01 = {
      vm_size               = "Standard_D3_v2"
      zone                  = "1"
      publisher             = "MicrosoftWindowsServer"
      offer                 = "WindowsServer"
      sku                   = "2016-Datacenter"
      version               = "latest"
      admin_user            = "azureuser"
      provision_vm_agent    = true
      patch_mode            = "AutomaticByPlatform"
      patch_assessment_mode = "AutomaticByPlatform"
      scheduled_shutdown    = true
      monitor               = true
      enable_av             = true
      backup                = false

      network = {
        nic-mgmt = {
          vnet                = "vnet-alz-vm-test-001"
          vnet_resource_group = "rg-alz-vm-test-001"
          subnet              = "snet-alz-vm-test-001"
          ip_address          = "192.168.99.5"
        }
      }

      data_disks = {
        data1 = {
          size          = 20
          lun           = 10
          type          = "Standard_LRS"
          create_option = "Empty"
        },
        data2 = {
          size          = 25
          lun           = 11
          type          = "Standard_LRS"
          create_option = "Empty"
        }
      }

      tags = {
        application = "windows_app"
        owner       = "alz"
      }
    }
  }

  vm_specifications_linux = {
    vm-test-nix-01 = {
      vm_size               = "Standard_D3_v2"
      zone                  = "1"
      publisher             = "Canonical"
      offer                 = "UbuntuServer"
      sku                   = "16.04-LTS"
      version               = "latest"
      admin_user            = "azureuser"
      provision_vm_agent    = true
      patch_mode            = "AutomaticByPlatform"
      patch_assessment_mode = "AutomaticByPlatform"
      scheduled_shutdown    = false
      monitor               = false
      backup                = false

      network = {
        nic-mgmt = {
          vnet                = "vnet-alz-vm-test-001"
          vnet_resource_group = "rg-alz-vm-test-001"
          subnet              = "snet-alz-vm-test-001"
          ip_address          = "192.168.99.6"
        }
      }

      data_disks = {}

      tags = {
        application = "linux_app"
        owner       = "alz"
      }
    }
  }
}
