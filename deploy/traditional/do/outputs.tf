
output "public_ipv4_address" {
  value = digitalocean_droplet.vm[*].ipv4_address
}

output "public_ipv6_address" {
  value = digitalocean_droplet.vm[*].ipv6_address
}

output "name_to_ipv4" {
  value = linode_domain_record.public_name_to_ipv4
}

output "name_to_ipv6" {
  value = linode_domain_record.public_name_to_ipv6
}

output "admin_user" {
  value = local.admin_username
}
