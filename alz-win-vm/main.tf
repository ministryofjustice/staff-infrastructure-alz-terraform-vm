
locals {
  # Collate NIC info along with other parameters that allow the NICs to be linked to the VM that specified them  
  nic_config = flatten([
    for vm_key, vm in var.vm_specifications : [
      for nic_key, nic in vm.network : {
        vm_name                       = vm_key
        nic                           = nic_key
        vnet                          = nic.vnet
        subnet                        = nic.subnet
        ip                            = nic.ip_address
        pip_id                        = nic.public_ip_id
        dns_servers                   = nic.custom_dns_servers
        vnet_rg                       = nic.vnet_resource_group
        enable_accelerated_networking = coalesce(nic.enable_accelerated_networking, false) # Set the default value to false
        enable_ip_forwarding          = coalesce(nic.enable_ip_forwarding, false)
        tags                          = vm.tags
      }
    ]
  ])

  # Collate disk info along with other parameters that allow disks to be linked to the VM that specified them
  data_disk_config = flatten([
    for vm_key, vm in var.vm_specifications : [
      for disk_key, disk in vm.data_disks : {
        vm_name       = vm_key
        disk_name     = disk_key
        lun           = disk.lun
        size          = disk.size
        type          = disk.type
        create_option = disk.create_option
        tags          = vm.tags
      }
    ]
  ])


  # Set some defaults for our VM spec

  # vm_specifications = defaults(var.vm_specifications, {
  #   os_disk_type          = "Standard_LRS"
  #   marketplace_image     = false
  #   admin_user            = "azureuser"
  #   license_type          = "None"
  #   scheduled_shutdown    = false
  #   monitor               = false
  #   enable_av             = false
  #   enable_host_enc       = false
  #   provision_vm_agent    = true
  #   patch_mode            = "AutomaticByPlatform"
  #   patch_assessment_mode = "AutomaticByPlatform"
  # })
}

# Create a managed identity - this is shared between all VM's created per module call
# Sharing an identity reduces churn in Azure AD and is better when working at scale
# https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/managed-identity-best-practice-recommendations

resource "random_string" "alz_win_identity" {
  length      = 10
  special     = false
  upper       = false
  min_numeric = 3
}

resource "azurerm_user_assigned_identity" "alz_win" {
  location            = data.azurerm_resource_group.alz_win.location
  name                = "mi-winvm-${random_string.alz_win_identity.result}"
  resource_group_name = data.azurerm_resource_group.alz_win.name
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# Generate a password for each VM, then push it to Keyvault
resource "random_password" "alz_win" {
  for_each         = var.vm_specifications
  length           = 16
  special          = true
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "!#$%&?"
}

resource "azurerm_key_vault_secret" "alz_win_passwords" {
  for_each     = var.vm_specifications
  name         = "${each.key}-password"
  value        = random_password.alz_win[each.key].result
  key_vault_id = data.azurerm_key_vault.core_spoke_keyvault.id
}

resource "azurerm_network_interface" "alz_win" {
  for_each = {
    for nic in local.nic_config : "${nic.nic}.${nic.vm_name}" => nic
  }
  name                          = each.key
  location                      = data.azurerm_resource_group.alz_win.location
  resource_group_name           = data.azurerm_resource_group.alz_win.name
  tags                          = each.value.tags
  dns_servers                   = each.value.dns_servers
  enable_accelerated_networking = each.value.enable_accelerated_networking
  enable_ip_forwarding          = each.value.enable_ip_forwarding

  ip_configuration {
    name                          = "ipconfig-${each.value.nic}"
    subnet_id                     = data.azurerm_subnet.alz_win["${each.value.vm_name}.${each.value.subnet}"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip
    public_ip_address_id          = each.value.pip_id
  }
}


# Using Windows Machine Resource
resource "azurerm_windows_virtual_machine" "alz_win" {
  for_each                   = var.vm_specifications
  name                       = each.key
  location                   = data.azurerm_resource_group.alz_win.location
  resource_group_name        = data.azurerm_resource_group.alz_win.name
  size                       = each.value.vm_size
  admin_username             = each.value.admin_user
  admin_password             = random_password.alz_win[each.key].result
  computer_name              = each.key # remember this can only be 15 characters max
  encryption_at_host_enabled = each.value.enable_host_enc
  license_type               = each.value.license_type
  patch_mode                 = each.value.patch_mode
  patch_assessment_mode      = each.value.patch_assessment_mode
  provision_vm_agent         = each.value.provision_vm_agent

  # Work out the functional tags based on the bools passed and combine those with the static tags specified for the VM
  tags = merge(each.value.tags,
    {
      "scheduled_shutdown" = each.value.scheduled_shutdown ? "true" : "false"
  })

  os_disk {
    name                 = "osDisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.spoke_log_diag_sa.primary_blob_endpoint
  }

  # Get the NIC ID's that have been defined for this VM only
  # here the each.key is still available from the top level "for_each = var.vm_specifications" and is the name of the FW
  network_interface_ids = [
    for nic in local.nic_config : azurerm_network_interface.alz_win["${nic.nic}.${nic.vm_name}"].id if nic.vm_name == each.key
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
    identity_ids = [azurerm_user_assigned_identity.alz_win.id]
  }
}


# Create a data disk from the disk list we flattened out in local.data_disk_config, using the disk + vm names combined together as a key
resource "azurerm_managed_disk" "alz_win" {
  for_each             = { for disk in local.data_disk_config : "${disk.disk_name}-${disk.vm_name}" => disk }
  name                 = each.key
  location             = data.azurerm_resource_group.alz_win.location
  resource_group_name  = data.azurerm_resource_group.alz_win.name
  storage_account_type = each.value.type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.size
  tags                 = each.value.tags
}

# Match up the disks and corresponding VM's
resource "azurerm_virtual_machine_data_disk_attachment" "alz_win" {
  for_each           = { for disk in local.data_disk_config : "${disk.disk_name}-${disk.vm_name}" => disk }
  managed_disk_id    = azurerm_managed_disk.alz_win[each.key].id # lookup the correct managed disk ID's using the combo of disk name and vm name
  virtual_machine_id = azurerm_windows_virtual_machine.alz_win[each.value.vm_name].id
  # lun                = (index(local.data_disk_config, each.value) + 10) # LUNS will be incremental numbers starting from 10
  lun     = each.value.lun
  caching = "ReadWrite"
}

# VM Extensions

# Antivirus
resource "azurerm_virtual_machine_extension" "alz_win_antivirus" {
  depends_on                 = [time_sleep.wait_30_seconds_ama] # See README
  for_each                   = { for k, v in var.vm_specifications : k => v if v.enable_av }
  name                       = "IaaSAntimalware"
  virtual_machine_id         = azurerm_windows_virtual_machine.alz_win[each.key].id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = "1.7"
  tags                       = each.value.tags
  auto_upgrade_minor_version = "true"
  settings = jsonencode({
    AntimalwareEnabled        = true,
    RealtimeProtectionEnabled = "true",
    ScheduledScanSettings = {
      isEnabled = "true",
      day       = "7",
      time      = "120",
      scanType  = "Quick"
    },
    Exclusions = lookup(var.vm_specifications[each.key], "antimalware_exclusions", {
      Extensions = ""
      Paths      = "C:\\Windows\\SoftwareDistribution\\Datastore;C:\\Windows\\SoftwareDistribution\\Datastore\\Logs;C:\\Windows\\Security\\Database"
      Processes  = "NTUser.dat*"
    })
  })

}

# Install Azure monitor agent and associate it to a data collection rule
resource "azurerm_virtual_machine_extension" "alz_win_ama" {
  for_each                   = { for k, v in var.vm_specifications : k => v if v.monitor }
  name                       = "AzureMonitorAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.alz_win[each.key].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  tags                       = each.value.tags
  settings                   = <<SETTINGS
    {
      "authentication": {
        "managedidentity": {
          "identifier-name": "mi_res_id",
          "identifier-value": "${azurerm_user_assigned_identity.alz_win.id}"
        }
      }
    }
    SETTINGS
}

# Also install "old" Log Analytics agent (extension called MicrosoftMonitoringAgent...) required to collect Change Tracking info
# This ultimately allows collection of data on Files, Services and Registry key changes so alerts can be created based on this
# This shouldn't have been required as this functionality is baked into the AMA installed above but it currently doesn't work...
# Confirmed with MS this should be fixed when it comes into General Availability 
resource "azurerm_virtual_machine_extension" "alz_win_mma" {
  for_each                   = { for k, v in var.vm_specifications : k => v if v.monitor }
  depends_on                 = [time_sleep.wait_30_seconds_av] # See README
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.alz_win[each.key].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<-BASE_SETTINGS
  {
    "azureResourceId" : "${azurerm_windows_virtual_machine.alz_win[each.key].id}",
    "stopOnMultipleConnections" : true,
    "workspaceId" : "${data.azurerm_log_analytics_workspace.core_spoke[0].workspace_id}"
  }
  BASE_SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
  {
    "workspaceKey" : "${data.azurerm_log_analytics_workspace.core_spoke[0].primary_shared_key}"
  }
  PROTECTED_SETTINGS

  tags = each.value.tags
}

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "alz_win" {
  for_each                = { for k, v in var.vm_specifications : k => v if v.monitor }
  name                    = azurerm_windows_virtual_machine.alz_win[each.key].name
  target_resource_id      = azurerm_windows_virtual_machine.alz_win[each.key].id
  data_collection_rule_id = data.azurerm_monitor_data_collection_rule.azure_monitor[0].id
  description             = "Association for ${azurerm_windows_virtual_machine.alz_win[each.key].name} for use with Azure Monitor Agent"
}

# The Azure API seems to have concurrency issues when Terraform is creating extensions
# See this issue - https://github.com/Azure/azure-rest-api-specs/issues/22434
# This is an attempt to workaround these in the short term until this issue is closed

resource "time_sleep" "wait_30_seconds_ama" {
  depends_on      = [azurerm_virtual_machine_extension.alz_win_ama]
  create_duration = "30s"
}

resource "time_sleep" "wait_30_seconds_av" {
  depends_on      = [azurerm_virtual_machine_extension.alz_win_antivirus]
  create_duration = "30s"
}
