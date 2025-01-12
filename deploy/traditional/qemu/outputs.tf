

output "uefi_disk_name" {
  value = shell_script.uefi_ram_disk[*].output["name"]
}

output "uefi_disk_device" {
  value = shell_script.uefi_ram_disk[*].output["device"]
}

output "boot_disk_name" {
  value = shell_script.boot_ram_disk[*].output["name"]
}

output "boot_disk_device" {
  value = shell_script.boot_ram_disk[*].output["device"]
}

output "qemu_instance_name" {
  value = shell_script.vm[*].output["name"]
}

output "qemu_instance_console" {
  value = shell_script.vm[*].output["console"]
}

output "qemu_instance_monitor" {
  value = shell_script.vm[*].output["monitor"]
}

output "qemu_instance_status" {
  value = shell_script.vm[*].output["status"]
}

output "qemu_instance_pid" {
  value = shell_script.vm[*].output["pid"]
}

# output "fully_qualifed_domain_name" {
#   value = local.fqdn
# }
