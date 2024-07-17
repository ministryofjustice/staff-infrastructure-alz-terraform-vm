locals {
  os_disk_ignore_changes = var.ignore_disk_changes ? [
    "os_disk[0].name",
    "os_disk[0].disk_size_gb",
    "os_disk[0].create_option",
    "os_disk[0].id"
  ] : []


  data_disk_ignore_changes = var.ignore_disk_changes ? [
    "managed_disk_id",
    "create_option"
  ] : []
}