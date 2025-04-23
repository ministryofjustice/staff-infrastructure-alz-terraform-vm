
locals {
  # Collate NIC info along with other parameters that allow the NICs to be linked to the VM that specified them  
  nic_config = flatten([
    for vm_key, vm in var.vm_specifications : [
      for nic_key, nic in vm.network : {
        vm_name                        = vm_key
        nic                            = nic_key
        vnet                           = nic.vnet
        subnet                         = nic.subnet
        ip                             = nic.ip_address
        pip_id                         = nic.public_ip_id
        dns_servers                    = nic.custom_dns_servers
        vnet_rg                        = nic.vnet_resource_group
        accelerated_networking_enabled = coalesce(nic.accelerated_networking_enabled, false) # Set the default value to false
        ip_forwarding_enabled          = coalesce(nic.ip_forwarding_enabled, false)
      }
    ]
  ])

  # Collate disk info along with other parameters that allow disks to be linked to the VM that specified them
  data_disk_config = flatten([
    for vm_key, vm in var.vm_specifications : [
      for disk_key, disk in vm.data_disks : {
        vm_name       = vm_key
        disk_name     = disk_key
        size          = disk.size
        lun           = disk.lun
        type          = disk.type
        create_option = disk.create_option
        zone          = disk.zone
      }
    ]
  ])
}

resource "random_string" "alz_linux_identity" {
  length      = 10
  special     = false
  upper       = false
  min_numeric = 3
}

resource "azurerm_user_assigned_identity" "alz_linux" {
  location            = data.azurerm_resource_group.alz_linux.location
  name                = "mi-linuxvm-${random_string.alz_linux_identity.result}"
  resource_group_name = data.azurerm_resource_group.alz_linux.name

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# Generate a password for each VM, then push it to Keyvault
resource "random_password" "alz_linux" {
  for_each         = var.vm_specifications
  length           = 16
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "!#$%&?"
}

resource "azurerm_key_vault_secret" "alz_linux_passwords" {
  for_each     = var.vm_specifications
  name         = "${each.key}-password"
  value        = random_password.alz_linux[each.key].result
  key_vault_id = data.azurerm_key_vault.core_spoke_keyvault.id
}

resource "azurerm_network_interface" "alz_linux" {
  for_each = {
    for nic in local.nic_config : "${nic.nic}-${nic.vm_name}" => nic
  }
  name                           = each.key
  location                       = data.azurerm_resource_group.alz_linux.location
  resource_group_name            = data.azurerm_resource_group.alz_linux.name
  dns_servers                    = each.value.dns_servers
  accelerated_networking_enabled = each.value.accelerated_networking_enabled
  ip_forwarding_enabled          = each.value.ip_forwarding_enabled

  ip_configuration {
    name                          = "ipconfig-${each.value.nic}"
    subnet_id                     = data.azurerm_subnet.alz_linux["${each.value.vm_name}.${each.value.subnet}"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip
    public_ip_address_id          = each.value.pip_id
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


# Using Linux Machine Resource
resource "azurerm_linux_virtual_machine" "alz_linux" {
  for_each                                               = var.vm_specifications
  name                                                   = each.key
  location                                               = data.azurerm_resource_group.alz_linux.location
  resource_group_name                                    = data.azurerm_resource_group.alz_linux.name
  size                                                   = each.value.vm_size
  zone                                                   = each.value.zone
  admin_username                                         = each.value.admin_user
  disable_password_authentication                        = false
  admin_password                                         = random_password.alz_linux[each.key].result
  bypass_platform_safety_checks_on_user_schedule_enabled = each.value.bypass_platform_safety_checks_on_user_schedule_enabled
  computer_name                                          = each.key # remember this can only be 15 characters max
  encryption_at_host_enabled                             = each.value.enable_host_enc
  patch_mode                                             = each.value.patch_mode
  patch_assessment_mode                                  = each.value.patch_assessment_mode
  provision_vm_agent                                     = each.value.provision_vm_agent
  custom_data                                            = each.value.custom_data


  os_disk {
    name                 = "osDisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.spoke_log_diag_sa.primary_blob_endpoint
  }

  # Get the NIC ID's that have been defined for this VM only
  # here the each.key is still available from the top level "for_each = var.vm_specifications" and is the name of the FW
  network_interface_ids = [
    for nic in local.nic_config : azurerm_network_interface.alz_linux["${nic.nic}-${nic.vm_name}"].id if nic.vm_name == each.key
  ]

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = each.value.version
  }

  dynamic "plan" {
    for_each = each.value.marketplace_image ? [1] : []
    content {
      name      = each.value.marketplace_plan.name
      publisher = each.value.marketplace_plan.publisher
      product   = each.value.marketplace_plan.product
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.alz_linux.id]
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


# Create a data disk from the disk list we flattened out in local.data_disk_config, using the disk + vm names combined together as a key
resource "azurerm_managed_disk" "alz_linux" {
  for_each             = { for disk in local.data_disk_config : "${disk.disk_name}-${disk.vm_name}" => disk }
  name                 = each.key
  location             = data.azurerm_resource_group.alz_linux.location
  resource_group_name  = data.azurerm_resource_group.alz_linux.name
  storage_account_type = each.value.type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.size
  zone                 = each.value.zone
  disk_iops_read_write = null
  lifecycle {
    ignore_changes = [
      create_option,
      source_resource_id, tags,
    ]
  }

}

# Match up the disks and corresponding VM's
resource "azurerm_virtual_machine_data_disk_attachment" "alz_linux" {
  for_each           = { for disk in local.data_disk_config : "${disk.disk_name}-${disk.vm_name}" => disk }
  managed_disk_id    = azurerm_managed_disk.alz_linux[each.key].id # lookup the correct managed disk ID's using the combo of disk name and vm name
  virtual_machine_id = azurerm_linux_virtual_machine.alz_linux[each.value.vm_name].id
  # lun                = (index(local.data_disk_config, each.value) + 10) # LUNS will be incremental numbers starting from 10
  lun     = each.value.lun
  caching = "ReadWrite"

  lifecycle {
    ignore_changes = [
      id,
      managed_disk_id
    ]
  }

}

# Install Azure monitor agent and associate it to a data collection rule
resource "azurerm_virtual_machine_extension" "alz_linux_ama" {
  for_each                   = { for k, v in var.vm_specifications : k => k if v.monitor }
  name                       = "AzureMonitorAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.alz_linux[each.key].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
    {
      "authentication": {
        "managedidentity": {
          "identifier-name": "mi_res_id",
          "identifier-value": "${azurerm_user_assigned_identity.alz_linux.id}"
        }
      }
    }
    SETTINGS
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "alz_linux" {
  for_each                = { for k, v in var.vm_specifications : k => k if v.monitor }
  name                    = azurerm_linux_virtual_machine.alz_linux[each.key].name
  target_resource_id      = azurerm_linux_virtual_machine.alz_linux[each.key].id
  data_collection_rule_id = data.azurerm_monitor_data_collection_rule.azure_monitor[0].id
  description             = "Association for ${azurerm_linux_virtual_machine.alz_linux[each.key].name} for use with Azure Monitor Agent"
}
