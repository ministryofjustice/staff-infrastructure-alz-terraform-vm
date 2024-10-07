variable "resource_group" {
  description = "Resource group to create the Virtual Machine(s) in"
  type        = string
}

# Set some optional defaults for our VM spec
variable "vm_specifications" {
  description = "Configuration parameters for each Virtual Machine specified"
  type = map(object({
    vm_size                                                = string
    marketplace_image                                      = optional(bool, false)
    marketplace_plan                                       = optional(map(string))
    zone                                                   = optional(string)
    publisher                                              = string
    offer                                                  = string
    sku                                                    = string
    version                                                = string
    os_disk_type                                           = optional(string, "Standard_LRS")
    admin_user                                             = optional(string, "azureuser")
    bypass_platform_safety_checks_on_user_schedule_enabled = optional(string, "false")
    patch_mode                                             = optional(string, "AutomaticByPlatform")
    patch_assessment_mode                                  = optional(string, "AutomaticByPlatform")
    provision_vm_agent                                     = optional(bool, true)
    monitor                                                = optional(bool, false)
    backup                                                 = optional(bool)
    enable_host_enc                                        = optional(bool, false)
    enable_av                                              = optional(bool, false)
    av_type_handler_version                                = optional(string, "1.7")
    license_type                                           = optional(string, "None")
    antimalware_exclusions = optional(object({
      Extensions = optional(string)
      Paths      = optional(string)
      Processes  = optional(string)
    }))

    network = map(object({
      vnet                           = string
      vnet_resource_group            = string
      subnet                         = string
      ip_address                     = string
      public_ip_id                   = optional(string)
      custom_dns_servers             = optional(list(string))
      accelerated_networking_enabled = optional(bool)
      ip_forwarding_enabled          = optional(bool)
    }))
    data_disks = map(object({
      size          = number
      lun           = number
      type          = string
      create_option = string
      zone          = optional(string)
    }))
  }))
}

variable "storage_account_boot_diag_name" {
  description = "Storage account to store Boot diagnostic logs for Virtual Machine(s)"
  type        = string
}

variable "storage_account_boot_diag_resource_group" {
  description = "Boot diagnostic Storage Account Resource Group"
  type        = string
}

variable "data_collection_rule_monitor_name" {
  description = "Name of the data collection rule used for Azure monitor agent data streams"
  type        = string
  default     = null
}

variable "data_collection_rule_monitor_resource_group" {
  description = "Resource group that contains the data collection rule used for Azure monitor agent data streams"
  type        = string
  default     = null
}

variable "log_analytics_workspace_name" {
  description = "Log analytics workspace to connect the MMA agent to"
  type        = string
  default     = null
}

variable "keyvault_name" {
  description = "User account credentials are generated and pushed here"
  type        = string
}

variable "keyvault_rg" {
  description = "Keyvault for credential storage Resource Group"
  type        = string
}

variable "recovery_vault_name" {
  description = "Vault used for backups - must be provided if any VM specifies 'backup' = 'true'"
  type        = string
  default     = null
}

variable "recovery_vault_resource_group" {
  description = "Vault resource group - must be provided if any VM specifies 'backup' = 'true'"
  type        = string
  default     = null
}

