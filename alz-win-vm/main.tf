
locals {
  # Collate NIC info along with other parameters that allow the NICs to be linked to the VM that specified them  
  nic_config = flatten([
    for vm_key, vm in var.vm_specifications : [
      for nic_key, nic in vm.network : {
        vm_name     = vm_key
        nic         = nic_key
        vnet        = nic.vnet
        subnet      = nic.subnet
        ip          = nic.ip_address
        dns_servers = nic.custom_dns_servers
        vnet_rg     = nic.vnet_resource_group
        tags        = vm.tags
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
        type          = disk.type
        create_option = disk.create_option
        tags          = vm.tags
      }
    ]
  ])


  # Set some defaults for our VM spec

  vm_specifications = defaults(var.vm_specifications, {
    os_disk_type       = "Standard_LRS"
    admin_user         = "azureuser"
    patch_class        = "none"
    scheduled_shutdown = false
    monitor            = false
    backup             = false
    enable_ade         = false
    enable_av          = false
    enable_host_enc    = false
  })

}

# Create a managed identity - this is shared between all VM's created per module call
# Sharing an identity reduces churn in Azure AD and is better when working at scale
# https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/managed-identity-best-practice-recommendations

resource "random_string" "alz_win_identity" {
  length = 10
  special = false
  upper = false
  min_numeric = 3
}

resource "azurerm_user_assigned_identity" "alz_win" {
  location            = data.azurerm_resource_group.alz_win.location
  name                = "win-vm-identity-${random_string.alz_win_identity.result}"
  resource_group_name = data.azurerm_resource_group.alz_win.name
}

# Generate a password for each VM, then push it to Keyvault
resource "random_password" "alz_win" {
  for_each         = local.vm_specifications
  length           = 16
  special          = true
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "!#$%&?"
}

resource "azurerm_key_vault_secret" "alz_win_passwords" {
  for_each     = local.vm_specifications
  name         = "${each.key}-password"
  value        = random_password.alz_win[each.key].result
  key_vault_id = data.azurerm_key_vault.core_spoke_keyvault.id
}

resource "azurerm_network_interface" "alz_win" {
  for_each = {
    for nic in local.nic_config : "${nic.nic}.${nic.vm_name}" => nic
  }
  name                = each.key
  location            = data.azurerm_resource_group.alz_win.location
  resource_group_name = data.azurerm_resource_group.alz_win.name
  tags                = each.value.tags
  dns_servers         = each.value.dns_servers

  ip_configuration {
    name                          = "ipconfig-${each.value.nic}"
    subnet_id                     = data.azurerm_subnet.alz_win["${each.value.vm_name}.${each.value.subnet}"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip
  }
}


# Using Windows Machine Resource
resource "azurerm_windows_virtual_machine" "alz_win" {
  for_each                   = local.vm_specifications
  name                       = each.key
  location                   = data.azurerm_resource_group.alz_win.location
  resource_group_name        = data.azurerm_resource_group.alz_win.name
  size                       = each.value.vm_size
  admin_username             = each.value.admin_user
  admin_password             = random_password.alz_win[each.key].result
  computer_name              = each.key # remember this can only be 15 characters max
  encryption_at_host_enabled = each.value.enable_host_enc

  # Work out the functional tags based on the bools passed and combine those with the static tags specified for the VM
  tags = merge(each.value.tags,
    {
      "UpdateClass"                    = each.value.patch_class
      "scheduled_shutdown"             = each.value.scheduled_shutdown ? "true" : "false"
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

  identity {
    type = "UserAssigned"
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
  lun                = (index(local.data_disk_config, each.value) + 10) # LUNS will be incremental numbers starting from 10
  caching            = "ReadWrite"
}

# Configure the backup in the RSV deployed in spoke if selected
resource "azurerm_backup_protected_vm" "alz_win" {
  # Loop through and setup backup in RSV for VM objects that have "backup" set to true
  for_each            = { for k, v in local.vm_specifications : k => k if v.backup }
  resource_group_name = var.recovery_vault_resource_group
  recovery_vault_name = var.recovery_vault_name
  backup_policy_id    = data.azurerm_backup_policy_vm.spoke_vm_backup_policy_1_yr[0].id # indexed because data source uses a count toggle
  source_vm_id        = azurerm_windows_virtual_machine.alz_win[each.key].id
}

# VM Extensions

# Antivirus
resource "azurerm_virtual_machine_extension" "alz_win_antivirus" {
  for_each                   = { for k, v in local.vm_specifications : k => k if v.enable_av }
  name                       = "IaaSAntimalware"
  virtual_machine_id         = azurerm_windows_virtual_machine.alz_win[each.key].id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = "true"
  settings                   = <<SETTINGS
  {
    "AntimalwareEnabled": true,
    "RealtimeProtectionEnabled": "true",
    "ScheduledScanSettings": {
        "isEnabled": "true",
        "day": "7",
        "time": "120",
        "scanType": "Quick"
    },
    "Exclusions": {
        "Extensions": "",
        "Paths": "C:\\Windows\\SoftwareDistribution\\Datastore;C:\\Windows\\SoftwareDistribution\\Datastore\\Logs;C:\\Windows\\Security\\Database",
        "Processes": "NTUser.dat*"
     }
  }
  SETTINGS
}

# Azure Disk Encryption (ADE) via VM extension with Bitlocker pointing at a key stored in KV
# We want to attach all the data disks before we run the encryption extension
resource "azurerm_virtual_machine_extension" "alz_win_ade_encryption" {
  for_each             = { for k, v in local.vm_specifications : k => k if v.enable_ade }
  depends_on           = [azurerm_virtual_machine_data_disk_attachment.alz_win]
  name                 = "AzureDiskEncrpytion"
  virtual_machine_id   = azurerm_windows_virtual_machine.alz_win[each.key].id
  publisher            = "Microsoft.Azure.Security"
  type                 = "AzureDiskEncryption"
  type_handler_version = "2.2"
  settings             = <<SETTINGS
    {
        "EncryptionOperation": "EnableEncryption",
        "KeyEncryptionAlgorithm": "RSA-OAEP",
        "KeyEncryptionKeyURL": "${data.azurerm_key_vault.core_spoke_keyvault.vault_uri}keys/${data.azurerm_key_vault_key.spoke_vm_disk_enc_key.name}/${data.azurerm_key_vault_key.spoke_vm_disk_enc_key.version}",
        "KeyVaultURL": "${data.azurerm_key_vault.core_spoke_keyvault.vault_uri}",
        "KeyVaultResourceId": "${data.azurerm_key_vault.core_spoke_keyvault.id}",
        "KekVaultResourceId": "${data.azurerm_key_vault.core_spoke_keyvault.id}",
        "VolumeType": "All"
    }
    SETTINGS
}

# Install Azure monitor agent

resource "azurerm_virtual_machine_extension" "alz_win_ama" {
  for_each             = { for k, v in local.vm_specifications : k => k if v.monitor }
  name                 = "AzureDiskEncrpytion"
  virtual_machine_id   = azurerm_windows_virtual_machine.alz_win[each.key].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.10.0.0"
  auto_upgrade_minor_version = true
  settings             = <<SETTINGS
    {
        "EncryptionOperation": "EnableEncryption",
        "KeyEncryptionAlgorithm": "RSA-OAEP",
        "KeyEncryptionKeyURL": "${data.azurerm_key_vault.core_spoke_keyvault.vault_uri}keys/${data.azurerm_key_vault_key.spoke_vm_disk_enc_key.name}/${data.azurerm_key_vault_key.spoke_vm_disk_enc_key.version}",
        "KeyVaultURL": "${data.azurerm_key_vault.core_spoke_keyvault.vault_uri}",
        "KeyVaultResourceId": "${data.azurerm_key_vault.core_spoke_keyvault.id}",
        "KekVaultResourceId": "${data.azurerm_key_vault.core_spoke_keyvault.id}",
        "VolumeType": "All"
    }
    SETTINGS
}