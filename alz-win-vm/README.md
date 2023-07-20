<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.2.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.33.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.33.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >=3.3.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_backup_protected_vm.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) | resource |
| [azurerm_key_vault_secret.alz_win_passwords](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_managed_disk.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_monitor_data_collection_rule_association.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_network_interface.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_user_assigned_identity.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_machine_data_disk_attachment.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.alz_win_ama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.alz_win_antivirus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.alz_win_mma](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_password.alz_win](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.alz_win_identity](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.wait_30_seconds_ama](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_30_seconds_av](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_backup_policy_vm.spoke_vm_backup_policy_1_yr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/backup_policy_vm) | data source |
| [azurerm_key_vault.core_spoke_keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_log_analytics_workspace.core_spoke](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_monitor_data_collection_rule.azure_monitor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_data_collection_rule) | data source |
| [azurerm_resource_group.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.spoke_log_diag_sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.alz_win](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_collection_rule_monitor_name"></a> [data\_collection\_rule\_monitor\_name](#input\_data\_collection\_rule\_monitor\_name) | Name of the data collection rule used for Azure monitor agent data streams | `string` | `null` | no |
| <a name="input_data_collection_rule_monitor_resource_group"></a> [data\_collection\_rule\_monitor\_resource\_group](#input\_data\_collection\_rule\_monitor\_resource\_group) | Resource group that contains the data collection rule used for Azure monitor agent data streams | `string` | `null` | no |
| <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name) | User account credentials are generated and pushed here | `string` | n/a | yes |
| <a name="input_keyvault_rg"></a> [keyvault\_rg](#input\_keyvault\_rg) | Keyvault for credential storage Resource Group | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | Log analytics workspace to connect the MMA agent to | `string` | `null` | no |
| <a name="input_recovery_vault_name"></a> [recovery\_vault\_name](#input\_recovery\_vault\_name) | Vault used for backups - must be provided if any VM specifies 'backup' = 'true' | `string` | `null` | no |
| <a name="input_recovery_vault_resource_group"></a> [recovery\_vault\_resource\_group](#input\_recovery\_vault\_resource\_group) | Vault resource group - must be provided if any VM specifies 'backup' = 'true' | `string` | `null` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group to create the Virtual Machine(s) in | `string` | n/a | yes |
| <a name="input_storage_account_boot_diag_name"></a> [storage\_account\_boot\_diag\_name](#input\_storage\_account\_boot\_diag\_name) | Storage account to store Boot diagnostic logs for Virtual Machine(s) | `string` | n/a | yes |
| <a name="input_storage_account_boot_diag_resource_group"></a> [storage\_account\_boot\_diag\_resource\_group](#input\_storage\_account\_boot\_diag\_resource\_group) | Boot diagnostic Storage Account Resource Group | `string` | n/a | yes |
| <a name="input_vm_specifications"></a> [vm\_specifications](#input\_vm\_specifications) | Configuration parameters for each Virtual Machine specified | <pre>map(object({<br>    vm_size               = string<br>    marketplace_image     = optional(bool)<br>    marketplace_plan      = optional(map(string))<br>    zone                  = string<br>    publisher             = string<br>    offer                 = string<br>    sku                   = string<br>    version               = string<br>    os_disk_type          = optional(string)<br>    admin_user            = string<br>    patch_mode            = optional(string)<br>    patch_assessment_mode = optional(string)<br>    provision_vm_agent    = optional(bool)<br>    scheduled_shutdown    = optional(bool)<br>    monitor               = optional(bool)<br>    backup                = optional(bool)<br>    enable_host_enc       = optional(bool)<br>    enable_av             = optional(bool)<br>    license_type          = optional(string)<br><br>    network = map(object({<br>      vnet                          = string<br>      vnet_resource_group           = string<br>      subnet                        = string<br>      ip_address                    = string<br>      public_ip_id                  = optional(string)<br>      custom_dns_servers            = optional(list(string))<br>      enable_accelerated_networking = optional(bool)<br>    }))<br>    data_disks = map(object({<br>      size          = number<br>      lun           = number<br>      type          = string<br>      create_option = string<br>    }))<br>    tags = map(string)<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nics"></a> [nics](#output\_nics) | Resource ID's for all created NICs |
| <a name="output_vm_identities"></a> [vm\_identities](#output\_vm\_identities) | Managed identities for all created VM's |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | Resource ID's for all created VM's |
<!-- END_TF_DOCS -->