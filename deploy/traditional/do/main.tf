
provider "digitalocean" {}

resource "digitalocean_project" "deployment_project" {
  name        = local.resource_prefix
  description = "The ${terraform.workspace} workspace for the ${var.project} application."
  # environment = local.config["capitalized"]
  resources   = digitalocean_droplet.vm[*].urn
}

resource "digitalocean_ssh_key" "deployer" {
  name       = "${local.resource_prefix}-deployer"
  public_key = var.deployer_public_key
}

resource "digitalocean_vpc" "vpc" {
  name     = "${local.resource_prefix}-vpc"
  region   = var.region
  ip_range = cidrsubnet(local.config["ipv4_cidr_block"], 8, 1)
}

resource "digitalocean_droplet" "vm" {

  count = local.config["vm_count"]

  name     = "f${count.index}.${terraform.workspace}.${var.project}"
  size     = local.config["droplet_size"]
  image    = local.config["debian_image"]
  region   = var.region
  ipv6     = true
  ssh_keys = [digitalocean_ssh_key.deployer.id]
  vpc_uuid = digitalocean_vpc.vpc.id

  user_data = <<EOF
#!/bin/bash
groupadd --gid 2001 ${local.deployer_username}
useradd --uid 2001 --gid 2001 --home-dir /home/${local.deployer_username} --create-home --shell /bin/bash --comment "project ${local.deployer_username}" --password \! ${local.deployer_username}
echo "${local.deployer_username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-${local.deployer_username}
mkdir -p /home/${local.deployer_username}/.ssh
chmod 700 /home/${local.deployer_username}/.ssh
echo "${digitalocean_ssh_key.deployer.public_key}" > /home/${local.deployer_username}/.ssh/authorized_keys
chmod 600 /home/${local.deployer_username}/.ssh/authorized_keys
chown -R ${local.deployer_username}:${local.deployer_username} /home/${local.deployer_username}/.ssh
EOF

  tags = local.common_tags
}

data "linode_domain" "domain" {
  domain = var.domain
}

locals {
  ipv4_addresses = toset([
    for vm in digitalocean_droplet.vm : vm.ipv4_address
  ])
 ipv6_addresses = toset([
    for vm in digitalocean_droplet.vm : vm.ipv6_address
  ])
}

resource "linode_domain_record" "public_name_to_ipv4" {

  count = local.config["vm_count"]

  domain_id   = data.linode_domain.domain.id
  name        = format("f${count.index}.%s.do.%s", terraform.workspace, var.project)
  record_type = "A"
  ttl_sec     = 300
  target      = digitalocean_droplet.vm[count.index].ipv4_address
}

resource "linode_domain_record" "public_name_to_ipv6" {

  count = local.config["vm_count"]

  domain_id   = data.linode_domain.domain.id
  name        = format("f${count.index}.%s.do.%s", terraform.workspace, var.project)
  record_type = "AAAA"
  ttl_sec     = 300
  target      = digitalocean_droplet.vm[count.index].ipv6_address
}

locals {
  environment_name_vm_index_combinations = toset(flatten([
    for environment_name in (local.config["environment_names"] != null ? local.config["environment_names"] : [terraform.workspace]) : [
      for vm_index in range(local.config["vm_count"]) : [
        "${environment_name}|${vm_index}"
      ]
    ]
  ]))
}

resource "linode_domain_record" "environment_public_name_to_ipv4" {

  for_each = toset(local.environment_name_vm_index_combinations)

  domain_id   = data.linode_domain.domain.id
  name        = format("%s%s", terraform.workspace != "production" ? "${split("|", each.value)[0]}." : "", var.project)
  record_type = "A"
  ttl_sec     = 300
  target      = digitalocean_droplet.vm[tonumber(split("|", each.value)[1])].ipv4_address

}

resource "linode_domain_record" "environment_public_name_to_ipv6" {

  for_each = toset(local.environment_name_vm_index_combinations)

  domain_id   = data.linode_domain.domain.id
  name        = format("%s%s", terraform.workspace != "production" ? "${split("|", each.value)[0]}." : "", var.project)
  record_type = "AAAA"
  ttl_sec     = 300
  target      = digitalocean_droplet.vm[tonumber(split("|", each.value)[1])].ipv6_address

}

data "local_file" "ansible_playbook" {
  for_each = fileset("../provision", "**/*.{yaml,yml,j2}")
  filename = "../provision/${each.value}"
}

resource "terraform_data" "bootstrap" {

  count = local.config["vm_count"]

  triggers_replace = [
    digitalocean_droplet.vm[count.index].id,
    sha256(join("", sort([for file in data.local_file.ansible_playbook : file.content_sha256])))
  ]
  provisioner "local-exec" {
    command = "ansible-playbook ../provision/public-bootstrap.yml --user ${local.deployer_username} -i ${digitalocean_droplet.vm[count.index].ipv4_address}, --extra-vars=\"upgrade=true\" --extra-vars=\"project=${var.project}\" --extra-vars=\"domain=${var.domain}\" --extra-vars=\"workspace=${terraform.workspace}\" --extra-vars=\"profile=${local.config.profile}\" --extra-vars=\"normalized_name=f${count.index}.${terraform.workspace}.${var.project}\" --extra-vars=\"target=do\""
  }
}
