# Pipeline requires these be set

variable "subscription_id" {
  description = "Subscription ID"
  default     = "4b068872-d9f3-41bc-9c34-ffac17cf96d6" # devl testing
}

variable "tenant_id" {
  description = "Tenant ID"
  default     = "0bb413d7-160d-4839-868a-f3d46537f6af" # dev
}

variable "ignore_disk_changes" {
  description = "Flag to control ignoring changes to OS and data disks"
  type        = bool
  default     = true
}