provider "azurerm" {
  alias = "spoke"
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = true
    }
  }
  tenant_id       = "0bb413d7-160d-4839-868a-f3d46537f6af"
  subscription_id = "4b068872-d9f3-41bc-9c34-ffac17cf96d6" # Devl testing
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "vm_module_tests" {}


resource "azurerm_resource_group" "vm_module_tests" {
  name     = "rg-alz-vm-test-001"
  location = "UK South"
  provider = azurerm.spoke
}
resource "azurerm_virtual_network" "vm_module_tests" {
  name                = "vnet-alz-vm-test-001"
  location            = azurerm_resource_group.vm_module_tests.location
  resource_group_name = azurerm_resource_group.vm_module_tests.name
  address_space       = ["192.168.99.0/24"]
  provider            = azurerm.spoke

  subnet {
    name           = "snet-alz-vm-test-001"
    address_prefix = "192.168.99.0/24"
  }
}


resource "azurerm_key_vault" "vm_module_tests" {
  name                      = "kv-alz-vm-test-001"
  location                  = azurerm_resource_group.vm_module_tests.location
  resource_group_name       = azurerm_resource_group.vm_module_tests.name
  tenant_id                 = data.azurerm_client_config.vm_module_tests.tenant_id
  enabled_for_disk_encryption     = true
  enable_rbac_authorization = true
  sku_name                  = "standard"
  provider                  = azurerm.spoke
}

resource "azurerm_key_vault_key" "vm_module_tests" {
  name         = "diskEncryption"
  depends_on   = [azurerm_role_assignment.vm_module_tests]
  provider     = azurerm.spoke
  key_vault_id = azurerm_key_vault.vm_module_tests.id
  key_type     = "RSA"
  key_size     = 2048


  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_role_assignment" "vm_module_tests" {
  scope                = azurerm_key_vault.vm_module_tests.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = "aff95dd1-5a32-4009-998f-06fdda1d36b4" # MoJO-DEVL-LandingZone
  provider             = azurerm.spoke
}

resource "azurerm_storage_account" "vm_module_tests" {
  name                            = "stalzvmtest7272"
  location                        = azurerm_resource_group.vm_module_tests.location
  resource_group_name             = azurerm_resource_group.vm_module_tests.name
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  provider                        = azurerm.spoke
}