
variable "resource_group" {
  description = "Resource group to create the Virtual Machine(s) in"
  type        = string
}

variable "vm_specifications" {
  description = "Configuration parameters for each Virtual Machine specified"
  type = map(object({
    vm_size               = string
    marketplace_image     = optional(bool)
    marketplace_plan      = optional(map(string))
    zone                  = string
    publisher             = string
    offer                 = string
    sku                   = string
    version               = string
    os_disk_type          = optional(string)
    admin_user            = string
    patch_class           = optional(string)
    patch_mode            = optional(string)
    patch_assessment_mode = optional(string)
    BypassPlatformSafetyChecksOnUserSchedule = optional(bool)
    provision_vm_agent    = optional(bool)
    scheduled_shutdown    = optional(bool)
    monitor               = optional(bool)
    backup                = optional(bool)
    enable_host_enc       = optional(bool)

    network = map(object({
      vnet                = string
      vnet_resource_group = string
      subnet              = string
      ip_address          = string
      public_ip_id        = optional(string)
      custom_dns_servers  = optional(list(string))
    }))
    data_disks = map(object({
      size          = number
      lun           = number
      type          = string
      create_option = string
    }))
    tags = map(string)
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
  description = "Vault resource group - - must be provided if any VM specifies 'backup' = 'true'"
  type        = string
  default     = null
}

