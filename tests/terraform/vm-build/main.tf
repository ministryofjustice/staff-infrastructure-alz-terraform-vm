provider "azurerm" {
  alias = "spoke"
  features {}
  tenant_id       = "0bb413d7-160d-4839-868a-f3d46537f6af"
  subscription_id = "4b068872-d9f3-41bc-9c34-ffac17cf96d6" # Devl testing
}

provider "random" {}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "vm_module_tests" {}

module "linux_vm_tests" {
  source                                   = "../../../alz-linux-vm"
  resource_group                           = "rg-alz-vm-test-001"
  vm_specifications                        = local.vm_specifications_linux
  storage_account_boot_diag_name           = "stalzvmtest7272"
  storage_account_boot_diag_resource_group = "rg-alz-vm-test-001"
  keyvault_name                            = "kv-alz-vm-test-001"
  keyvault_rg                              = "rg-alz-vm-test-001"
  providers                                = { azurerm = azurerm.spoke }
}

module "windows_vm_tests" {
  source                                      = "../../../alz-win-vm"
  resource_group                              = "rg-alz-vm-test-001"
  vm_specifications                           = local.vm_specifications_win
  storage_account_boot_diag_name              = "stalzvmtest7272"
  storage_account_boot_diag_resource_group    = "rg-alz-vm-test-001"
  keyvault_name                               = "kv-alz-vm-test-001"
  keyvault_rg                                 = "rg-alz-vm-test-001"
  data_collection_rule_monitor_name           = "dcr-alz-vm-test-001"
  data_collection_rule_monitor_resource_group = "rg-alz-vm-test-001"
  log_analytics_workspace_name                = "log-alz-vm-test-001"
  providers                                   = { azurerm = azurerm.spoke }
}