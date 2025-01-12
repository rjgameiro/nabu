
provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "deployment_resource_group" {
  name = "rg-${var.project}-${terraform.workspace}"
}

resource "azurerm_ssh_public_key" "deployer" {
  name                = "${local.resource_prefix}-deployer"
  resource_group_name = data.azurerm_resource_group.deployment_resource_group.name
  location            = data.azurerm_resource_group.deployment_resource_group.location
  public_key          = var.deployer_public_key
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = [local.config["ipv4_cidr_block"], "fd00::/56"]
  location            = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name = data.azurerm_resource_group.deployment_resource_group.name
}

# Subnet 1
resource "azurerm_subnet" "public_subnet_1" {
  name                 = "${local.resource_prefix}-public-subnet-1"
  resource_group_name  = data.azurerm_resource_group.deployment_resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes = [
    cidrsubnet(tolist(azurerm_virtual_network.virtual_network.address_space)[0], 8, 1),
    cidrsubnet(tolist(azurerm_virtual_network.virtual_network.address_space)[1], 8, 1)
  ]
}

resource "azurerm_network_security_group" "security_group" {
  name                = "${local.resource_prefix}-nsg"
  location            = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name = data.azurerm_resource_group.deployment_resource_group.name
}

resource "azurerm_network_security_rule" "inbound_ssh" {
  name                        = "${local.resource_prefix}-allow-ssh-inbound"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.deployment_resource_group.name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_network_security_rule" "inbound_http" {
  name                        = "${local.resource_prefix}-allow-http-inbound"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.deployment_resource_group.name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_network_security_rule" "inbound_https" {
  name                        = "${local.resource_prefix}-allow-https-inbound"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.deployment_resource_group.name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_network_security_rule" "inbound_icmp" {
  name                        = "${local.resource_prefix}-allow-icmp-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.deployment_resource_group.name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_public_ip" "my_terraform_public_ipv4_ip" {

  count = local.config["vm_count"]

  name                = "${local.resource_prefix}-public-ipv4-ip-${count.index}"
  location            = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name = data.azurerm_resource_group.deployment_resource_group.name
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "my_terraform_public_ipv6_ip" {

  count = local.config["vm_count"]

  name                = "${local.resource_prefix}-public-ipv6-ip-${count.index}"
  location            = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name = data.azurerm_resource_group.deployment_resource_group.name
  allocation_method   = "Static"
  ip_version          = "IPv6"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {

  count = local.config["vm_count"]

  name                = "${local.resource_prefix}-nic-${count.index}"
  location            = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name = data.azurerm_resource_group.deployment_resource_group.name

  ip_configuration {
    primary                       = true
    name                          = "ipv4-nic-configuration"
    subnet_id                     = azurerm_subnet.public_subnet_1.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ipv4_ip[count.index].id
  }

  ip_configuration {
    name                          = "ipv6-nic-configuration"
    subnet_id                     = azurerm_subnet.public_subnet_1.id
    private_ip_address_version    = "IPv6"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ipv6_ip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "my-nsg-assoc" {
  count                     = local.config["vm_count"]
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.security_group.id
}

resource "azurerm_storage_account" "vm_boot_diagnostics" {
  name                     = "st${var.project}${terraform.workspace}diag"
  location                 = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name      = data.azurerm_resource_group.deployment_resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "vm" {

  count = local.config["vm_count"]

  name                  = "f${count.index}.${terraform.workspace}.${var.project}"
  location              = data.azurerm_resource_group.deployment_resource_group.location
  resource_group_name   = data.azurerm_resource_group.deployment_resource_group.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = local.config["instance_size"]
  priority              = local.config["priority"]
  eviction_policy       = try(local.config["eviction_policy"], null)
  max_bid_price         = try(local.config["max_bid_price"], null)

  os_disk {
    name                 = "${local.resource_prefix}-frontend-disk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = local.config["debian_image_sku"]
    version   = "latest"
  }

  admin_username = local.admin_username

  admin_ssh_key {
    username   = local.admin_username
    public_key = azurerm_ssh_public_key.deployer.public_key
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.vm_boot_diagnostics.primary_blob_endpoint
  }

  custom_data = base64encode(
    <<EOF
#!/bin/bash
groupadd --gid 2001 ${local.deployer_username}
useradd --uid 2001 --gid 2001 --home-dir /home/${local.deployer_username} --create-home --shell /bin/bash --comment "project ${local.deployer_username}" --password \! ${local.deployer_username}
echo "${local.deployer_username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-${local.deployer_username}
mkdir -p /home/${local.deployer_username}/.ssh
chmod 700 /home/${local.deployer_username}/.ssh
echo "${azurerm_ssh_public_key.deployer.public_key}" > /home/${local.deployer_username}/.ssh/authorized_keys
chmod 600 /home/${local.deployer_username}/.ssh/authorized_keys
chown -R ${local.deployer_username}:${local.deployer_username} /home/${local.deployer_username}/.ssh
EOF
  )

  tags = local.common_tags
}

# locals {
#   public_ipv4_address = try([for cidr in azurerm_linux_virtual_machine.vm.public_ip_addresses : cidr if can(regex("^[0-9\\.]+$", cidr))][0], null)
#   public_ipv6_address = try([for cidr in azurerm_linux_virtual_machine.vm.public_ip_addresses : cidr if can(regex("^[0-9a-fA-F:]+$", cidr))][0], null)
# }

data "linode_domain" "domain" {
  domain = var.domain
}

resource "linode_domain_record" "public_name_to_ipv4" {

  count = local.config["vm_count"]

  domain_id   = data.linode_domain.domain.id
  name        = format("f${count.index}.%s.azure.%s", terraform.workspace, var.project)
  record_type = "A"
  ttl_sec     = 300
  target      = try([for cidr in azurerm_linux_virtual_machine.vm[count.index].public_ip_addresses : cidr if can(regex("^[0-9\\.]+$", cidr))][0], null)
}

resource "linode_domain_record" "public_name_to_ipv6" {

  count = local.config["vm_count"]

  domain_id   = data.linode_domain.domain.id
  name        = format("f${count.index}.%s.azure.%s", terraform.workspace, var.project)
  record_type = "AAAA"
  ttl_sec     = 300
  target      = try([for cidr in azurerm_linux_virtual_machine.vm[count.index].public_ip_addresses : cidr if can(regex("^[0-9a-fA-F:]+$", cidr))][0], null)
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
  target      = try([for cidr in azurerm_linux_virtual_machine.vm[tonumber(split("|", each.value)[1])].public_ip_addresses : cidr if can(regex("^[0-9\\.]+$", cidr))][0], null)

}

resource "linode_domain_record" "environment_public_name_to_ipv6" {

  for_each = toset(local.environment_name_vm_index_combinations)

  domain_id   = data.linode_domain.domain.id
  name        = format("%s%s", terraform.workspace != "production" ? "${split("|", each.value)[0]}." : "", var.project)
  record_type = "AAAA"
  ttl_sec     = 300
  target      = try([for cidr in azurerm_linux_virtual_machine.vm[tonumber(split("|", each.value)[1])].public_ip_addresses : cidr if can(regex("^[0-9a-fA-F:]+$", cidr))][0], null)

}

data "local_file" "ansible_playbook" {
  for_each = fileset("../provision", "**/*.{yaml,yml,j2}")
  filename = "../provision/${each.value}"
}

resource "terraform_data" "bootstrap" {

  count = local.config["vm_count"]

  triggers_replace = [
    azurerm_linux_virtual_machine.vm[count.index].id,
    sha256(join("", sort([for file in data.local_file.ansible_playbook : file.content_sha256])))
  ]
  provisioner "local-exec" {
    command = "ansible-playbook ../provision/public-bootstrap.yml --user ${local.deployer_username} -i ${linode_domain_record.public_name_to_ipv4[count.index].target}, --extra-vars=\"upgrade=true\" --extra-vars=\"project=${var.project}\" --extra-vars=\"domain=${var.domain}\" --extra-vars=\"workspace=${terraform.workspace}\" --extra-vars=\"profile=${local.config.profile}\" --extra-vars=\"normalized_name=f${count.index}.${terraform.workspace}.${var.project}\" --extra-vars=\"target=azure\""
  }
}
