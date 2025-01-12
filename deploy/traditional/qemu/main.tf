
provider "shell" {
  environment           = {}
  sensitive_environment = {}
  interpreter           = ["/bin/bash", "-c"]
  enable_parallelism    = false
}

resource "shell_script" "uefi_ram_disk" {

  count = local.config["vm_count"]

  lifecycle_commands {
    create = file("${path.module}/handlers/ram-disk-create.sh")
    read   = file("${path.module}/handlers/ram-disk-read.sh")
    delete = file("${path.module}/handlers/ram-disk-delete.sh")
  }

  environment = {
    size_512b  = 131072
    name       = "${local.resource_prefix}-${count.index}-ram_uefi_disk"
    image_path = var.uefi_image_path
  }

}

resource "shell_script" "boot_ram_disk" {

  count = local.config["vm_count"]

  lifecycle_commands {
    create = file("${path.module}/handlers/ram-disk-create.sh")
    read   = file("${path.module}/handlers/ram-disk-read.sh")
    delete = file("${path.module}/handlers/ram-disk-delete.sh")
  }

  environment = {
    size_512b  = 16777216
    name       = "${local.resource_prefix}-${count.index}-ram_boot_disk"
    image_path = var.boot_image_path
  }

  depends_on = [shell_script.uefi_ram_disk]

}

resource "shell_script" "vm" {

  count = local.config["vm_count"]

  lifecycle_commands {
    create = file("${path.module}/handlers/qemu-instance-create.sh")
    read   = file("${path.module}/handlers/qemu-instance-read.sh")
    delete = file("${path.module}/handlers/qemu-instance-delete.sh")
  }

  environment = {
    name         = "f${count.index}.${terraform.workspace}.${var.project}"
    ncpus        = 2
    memory       = 2048
    uefi_device  = shell_script.uefi_ram_disk[count.index].output["device"]
    boot_device  = shell_script.boot_ram_disk[count.index].output["device"]
    host_forward = "tcp::${2022 + count.index}-:22, tcp::${2080 + count.index}-:80, tcp::${2443 + count.index}-:443"
  }

  depends_on = [shell_script.uefi_ram_disk, shell_script.boot_ram_disk]

}

resource "shell_script" "vm_name_to_local_ip" {

  count = local.config["vm_count"]

  lifecycle_commands {
    create = file("${path.module}/handlers/file-line-entry-create.sh")
    read   = file("${path.module}/handlers/file-line-entry-read.sh")
    delete = file("${path.module}/handlers/file-line-entry-delete.sh")
  }

  environment = {
    entry       = shell_script.vm[count.index].output.name
    prefix      = "127.0.0.1"
    file        = "/etc/hosts"
    become_root = "yes"
  }

}

resource "shell_script" "ssh_config_entry" {

  count = local.config["vm_count"]

  lifecycle_commands {
    create = file("${path.module}/handlers/ssh-config-entry-create.sh")
    read   = file("${path.module}/handlers/ssh-config-entry-read.sh")
    delete = file("${path.module}/handlers/ssh-config-entry-delete.sh")
  }

  environment = {
    ssh_fqdn = shell_script.vm[count.index].output.name
    ssh_port = 2022 + count.index
  }

  depends_on = [shell_script.vm]

}

# resource "ansible_host" "host" {
#
#   count = local.config["vm_count"]
#
#   name   = shell_script.vm[count.index].output.name
#   groups = ["public"]
#
#   variables = {
#     ansible_host = "127.0.0.1"
#     ansible_port = 2022 + count.index
#     ansible_user = "deployer"
#   }
#
# }
#
# resource "ansible_playbook" "provision" {
#
#   count = local.config["vm_count"]
#
#   playbook = "../provision/public-bootstrap.yml"
#   # name     = shell_script.vm[count.index].output.name
#   groups   = ["public"]
#   replayable = true
#
#   extra_vars = {
#     project         = var.project
#     domain          = var.domain
#     target          = "qemu"
#     workspace       = terraform.workspace
#     profile         = local.config["profile"]
#     upgrade         = false
#     normalized_name = shell_script.vm[count.index].output.name
#   }
#
#   depends_on = [shell_script.vm, shell_script.ssh_config_entry /*, ansible_host.host*/]
#
# }

resource "shell_script" "environment_name_to_local_ip" {

  for_each = toset(
    local.config["environment_names"] != null ? local.config["environment_names"] : [terraform.workspace]
  )

  lifecycle_commands {
    create = file("${path.module}/handlers/file-line-entry-create.sh")
    read   = file("${path.module}/handlers/file-line-entry-read.sh")
    delete = file("${path.module}/handlers/file-line-entry-delete.sh")
  }

  environment = {
    entry       = format("%s%s.%s", terraform.workspace != "production" ? "${each.value}." : "", var.project, var.domain)
    prefix      = "127.0.0.1"
    file        = "/etc/hosts"
    become_root = "yes"
  }

}


data "local_file" "ansible_provisioner" {
  for_each = fileset("../provision", "**/*.{yaml,yml,j2}")
  filename = "../provision/${each.value}"
}

resource "terraform_data" "provisioner" {
  count = local.config["vm_count"]

  triggers_replace = [
    shell_script.vm[count.index].id,
    sha256(join("", sort([for file in data.local_file.ansible_provisioner : file.content_sha256])))

  ]
  provisioner "local-exec" {
    command = "ansible-playbook ../provision/public-bootstrap.yml --user ${local.deployer_username} -i ${shell_script.vm[count.index].output.name}, --extra-vars=\"upgrade=true\" --extra-vars=\"project=${var.project}\" --extra-vars=\"domain=${var.domain}\" --extra-vars=\"workspace=${terraform.workspace}\" --extra-vars=\"profile=${local.config.profile}\" --extra-vars=\"normalized_name=${shell_script.vm[count.index].output.name}\" --extra-vars=\"target=qemu\""
  }

  depends_on = [
    shell_script.vm,
    shell_script.vm_name_to_local_ip,
    shell_script.environment_name_to_local_ip,
    shell_script.environment_name_to_local_ip,
    shell_script.ssh_config_entry,
  ]
}
