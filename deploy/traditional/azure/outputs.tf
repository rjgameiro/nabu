
# output "public_ipv4_address" {
#   value = try([for cidr in azurerm_linux_virtual_machine.vm.public_ip_addresses : cidr if can(regex("^[0-9\\.]+$", cidr))][0], null)
# }
#
# output "public_ipv6_address" {
#   value = try([for cidr in azurerm_linux_virtual_machine.vm.public_ip_addresses : cidr if can(regex("^[0-9a-fA-F:]+$", cidr))][0], null)
# }

output "name_to_ipv4" {
  value = linode_domain_record.public_name_to_ipv4[*].target
}

output "name_to_ipv6" {
  value = linode_domain_record.public_name_to_ipv6[*].target
}

output "admin_user" {
  value = local.admin_username
}
