# Networking and resource placement data lookups
data "azurerm_resource_group" "alz_linux" {
  name = var.resource_group
}

data "azurerm_subnet" "alz_linux" {
  for_each = {
    for nic in local.nic_config : "${nic.vm_name}.${nic.subnet}" => nic
  }
  name                 = each.value.subnet
  virtual_network_name = each.value.vnet
  resource_group_name  = each.value.vnet_rg
}


# Spoke service data lookup - for password management, backups, logs
data "azurerm_key_vault" "core_spoke_keyvault" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_rg
}

data "azurerm_key_vault_key" "spoke_vm_disk_enc_key" {
  key_vault_id = data.azurerm_key_vault.core_spoke_keyvault.id
  name         = "diskEncryption" # this key is created by our spoke module, so I can't see why it would ever change
}

data "azurerm_storage_account" "spoke_log_diag_sa" {
  name                = var.storage_account_boot_diag_name
  resource_group_name = var.storage_account_boot_diag_resource_group
}

data "azurerm_backup_policy_vm" "spoke_vm_backup_policy_1_yr" {
  count               = var.recovery_vault_name != null ? 1 : 0
  name                = "Policy-1-Year-Backup"
  recovery_vault_name = var.recovery_vault_name
  resource_group_name = var.recovery_vault_resource_group
}

data "azurerm_monitor_data_collection_rule" "azure_monitor" {
  count               = var.data_collection_rule_monitor_name != null ? 1 : 0
  name                = var.data_collection_rule_monitor_name
  resource_group_name = var.data_collection_rule_monitor_resource_group
}