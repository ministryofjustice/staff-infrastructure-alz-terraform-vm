locals {
  vm_specifications_win = {
    vm-test-win-007 = {
      vm_size                                                = "Standard_D2s_v3"
      zone                                                   = "1"
      publisher                                              = "MicrosoftWindowsServer"
      offer                                                  = "WindowsServer"
      sku                                                    = "2019-Datacenter"
      version                                                = "latest"
      admin_user                                             = "azureuser"
      bypass_platform_safety_checks_on_user_schedule_enabled = true
      provision_vm_agent                                     = true
      patch_mode                                             = "AutomaticByPlatform"
      patch_assessment_mode                                  = "AutomaticByPlatform"
      monitor                                                = true
      enable_av                                              = false
      av_type_handler_version                                = "1.3"
      backup                                                 = false
      antimalware_exclusions = {
        Extensions = ".jpeg"
        Paths      = "C:\\Windows\\debug"
        Processes  = "vssvc.exe"
      }

      network = {
        nic-mgmt = {
          vnet                           = "vnet-alz-vm-test-001"
          vnet_resource_group            = "rg-alz-vm-test-001"
          subnet                         = "snet-alz-vm-test-001"
          ip_address                     = "192.168.99.55"
          accelerated_networking_enabled = true
          ip_forwarding_enabled          = true
        }
      }

      data_disks = {
        data1 = {
          size          = 20
          lun           = 10
          type          = "Premium_ZRS"
          create_option = "Empty"
        },
        data2 = {
          size          = 25
          lun           = 11
          type          = "Standard_LRS"
          create_option = "Empty"
          zone          = 1
        }
      }

    }
  }

  vm_specifications_linux = {
    vm-test-nix-011 = {
      vm_size                                                = "Standard_D2s_v3"
      zone                                                   = "1"
      publisher                                              = "Canonical"
      offer                                                  = "UbuntuServer"
      sku                                                    = "16.04-LTS"
      version                                                = "latest"
      admin_user                                             = "azureuser"
      bypass_platform_safety_checks_on_user_schedule_enabled = false
      provision_vm_agent                                     = true
      patch_mode                                             = "AutomaticByPlatform"
      patch_assessment_mode                                  = "AutomaticByPlatform"
      monitor                                                = false
      backup                                                 = false

      network = {
        nic-mgmt = {
          vnet                           = "vnet-alz-vm-test-001"
          vnet_resource_group            = "rg-alz-vm-test-001"
          subnet                         = "snet-alz-vm-test-001"
          ip_address                     = "192.168.99.66"
          accelerated_networking_enabled = true
          ip_forwarding_enabled          = true
        }
      }

      data_disks = {
        data1 = {
          size          = 20
          lun           = 10
          type          = "Premium_ZRS"
          create_option = "Empty"
        },
        data2 = {
          size          = 25
          lun           = 11
          type          = "Standard_LRS"
          create_option = "Empty"
          zone          = 1
      } }

    }
  }
}