
provider "aws" {
  // region = "eu-west-1"
  assume_role {
    role_arn = format("arn:aws:iam::%s:role/%sRoleFor%s", var.deployment_account_id, title(var.project), title(terraform.workspace))
  }
  default_tags {
    tags = local.common_tags
  }
}
provider "linode" {}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.resource_prefix}-deployer"
  public_key = var.deployer_public_key
  tags = {
    Name = "${local.resource_prefix}-deployer"
  }
}

resource "aws_vpc" "vpc" {
  enable_dns_support               = true
  enable_dns_hostnames             = true
  cidr_block                       = local.config["ipv4_cidr_block"]
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${local.resource_prefix}-vpc"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id                          = aws_vpc.vpc.id
  availability_zone               = "eu-west-1a"
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)
  map_public_ip_on_launch         = true
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true
  tags = {
    Name = "${local.resource_prefix}-public-subnet-1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.resource_prefix}-igw"
  }
}

resource "aws_default_route_table" "default-route-table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.resource_prefix}-default-route-table"
  }
}

resource "aws_route_table_association" "route-table-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_default_route_table.default-route-table.id
}

resource "aws_default_security_group" "default_security_group" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "security_group" {
  name   = "${local.resource_prefix}-security-group"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.resource_prefix}-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv4_ssh_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.resource_prefix}-ssh-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv6_ssh_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv6         = "::/0"
  tags = {
    Name = "${local.resource_prefix}-ssh-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv4_http_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.resource_prefix}-http-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv6_http_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv6         = "::/0"
  tags = {
    Name = "${local.resource_prefix}-http-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv4_https_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.resource_prefix}-https-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv6_https_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = "::/0"
  tags = {
    Name = "${local.resource_prefix}-https-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv4_icmp_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.resource_prefix}-icmp-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv6_icmp_ingress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "icmpv6"
  from_port         = -1
  to_port           = -1
  cidr_ipv6         = "::/0"
  tags = {
    Name = "${local.resource_prefix}-icmpv6-ingress-rule"
  }
}

resource "aws_vpc_security_group_egress_rule" "ipv4_all_egress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.resource_prefix}-ipv4-all-egress-rule"
  }
}

resource "aws_vpc_security_group_egress_rule" "ipv6_all_egress_rule" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
  tags = {
    Name = "${local.resource_prefix}-ipv6-all-egress-rule"
  }
}

resource "aws_default_network_acl" "default-network-acl" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  subnet_ids = [
    aws_subnet.public-subnet-1.id
  ]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags = {
    Name = "${local.resource_prefix}-default-network-acl"
  }

}

data "aws_ami" "debian_12" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vm" {

  count = local.config["vm_count"]

  ami                    = data.aws_ami.debian_12.id // "ami-0c810c0a5da915a2d"
  instance_type          = local.config["instance_type"]
  subnet_id              = aws_subnet.public-subnet-1.id
  key_name               = aws_key_pair.deployer.key_name
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash
groupadd --gid 2001 ${local.deployer_username}
useradd --uid 2001 --gid 2001 --home-dir /home/${local.deployer_username} --create-home --shell /bin/bash --comment "project ${local.deployer_username}" --password \! ${local.deployer_username}
echo "${local.deployer_username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-${local.deployer_username}
mkdir -p /home/${local.deployer_username}/.ssh
chmod 700 /home/${local.deployer_username}/.ssh
echo "${aws_key_pair.deployer.public_key}" > /home/${local.deployer_username}/.ssh/authorized_keys
chmod 600 /home/${local.deployer_username}/.ssh/authorized_keys
chown -R ${local.deployer_username}:${local.deployer_username} /home/${local.deployer_username}/.ssh
EOF

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "f${count.index}.${terraform.workspace}.${var.project}"
  }
  depends_on = [aws_internet_gateway.igw]
}

data "linode_domain" "domain" {
  domain = var.domain
}

resource "linode_domain_record" "public_name_to_ipv4" {

  count = local.config["vm_count"]

  domain_id   = data.linode_domain.domain.id
  name        = format("f${count.index}.%s.aws.%s", terraform.workspace, var.project)
  record_type = "A"
  ttl_sec     = 300
  target      = aws_instance.vm[count.index].public_ip

}

resource "linode_domain_record" "public_name_to_ipv6" {

  count = local.config["vm_count"]

  domain_id   = data.linode_domain.domain.id
  name        = format("f${count.index}.%s.aws.%s", terraform.workspace, var.project)
  record_type = "AAAA"
  ttl_sec     = 300
  target      = try(aws_instance.vm[count.index].ipv6_addresses[0], null)

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
  target      = aws_instance.vm[tonumber(split("|", each.value)[1])].public_ip

}

resource "linode_domain_record" "environment_public_name_to_ipv6" {

  for_each = toset(local.environment_name_vm_index_combinations)

  domain_id   = data.linode_domain.domain.id
  name        = format("%s%s", terraform.workspace != "production" ? "${split("|", each.value)[0]}." : "", var.project)
  record_type = "AAAA"
  ttl_sec     = 300
  target      = try(aws_instance.vm[tonumber(split("|", each.value)[1])].ipv6_addresses[0], null)

}

data "local_file" "ansible_playbook" {
  for_each = fileset("../provision", "**/*.{yaml,yml,j2}")
  filename = "../provision/${each.value}"
}

resource "terraform_data" "bootstrap" {

  count = local.config["vm_count"]

  triggers_replace = [
    aws_instance.vm[count.index].id,
    sha256(join("", sort([for file in data.local_file.ansible_playbook : file.content_sha256])))
  ]
  provisioner "local-exec" {
    command = "ansible-playbook ../provision/public-bootstrap.yml --user ${local.deployer_username} -i ${aws_instance.vm[count.index].public_ip}, --extra-vars=\"upgrade=true\" --extra-vars=\"project=${var.project}\" --extra-vars=\"domain=${var.domain}\" --extra-vars=\"workspace=${terraform.workspace}\" --extra-vars=\"profile=${local.config.profile}\" --extra-vars=\"normalized_name=f${count.index}.${terraform.workspace}.${var.project}\" --extra-vars=\"target=aws\""
  }
}
