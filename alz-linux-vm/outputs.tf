output "vm_ids" {
  description = "Resource ID's for all created VM's"
  value = {
    for k, v in azurerm_linux_virtual_machine.alz_linux : k => v.id
  }
}

output "vm_identities" {
  description = "Managed identities for all created VM's"
  value = {
    for k, v in azurerm_linux_virtual_machine.alz_linux : k => v.identity
  }
}

output "nics" {
  description = "Resource ID's for all created NICs"
  value = {
    for k, v in azurerm_network_interface.alz_linux : k => v.id
  }
}