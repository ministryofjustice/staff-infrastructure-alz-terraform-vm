output "vm_ids" {
  description = "Resource ID's for all created VM's"
  value = {
    for k, v in azurerm_windows_virtual_machine.alz_win : k => v.id
  }
}

output "vm_identities" {
  description = "Managed identities for all created VM's"
  value = {
    for k, v in azurerm_windows_virtual_machine.alz_win : k => v.identity
  }
}

output "nics" {
  description = "Resource ID's for all created NICs"
  value = {
    for k, v in azurerm_network_interface.alz_win : k => v.id
  }
}

output "debug_vm_specifications" {
  value = var.vm_specifications
}