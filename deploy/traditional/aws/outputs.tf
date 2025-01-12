
output "public_ipv4_address" {
  value = aws_instance.vm[*].public_ip
}

output "public_ipv6_address" {
  value = try(aws_instance.vm[*].ipv6_addresses[0], null)
}

output "admin_user" {
  value = local.admin_username
}
