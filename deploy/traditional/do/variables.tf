
variable "project" {
  description = "The name of the project."
}

variable "domain" {
  description = "The domain where the DNS records will be created."
}

variable "owner" {
  description = "The email of the owner of the project (for tagging purposes)."
  type        = string
  sensitive   = true
}

variable "deployer_public_key" {
  description = "The public key of the application deployer."
  type        = string
}

variable "region" {
  description = "The region where to deploy the resources."
  type        = string
}

locals {
  config = local.configs[terraform.workspace]
  configs = {
    sandbox = {
      capitalized       = "Sandbox"
      profile           = "debug"
      ipv4_cidr_block   = "10.20.0.0/16"
      droplet_size      = "s-1vcpu-1gb"   // https://slugs.do-api.dev
      debian_image      = "debian-12-x64" // https://docs.digitalocean.com/products/droplets/details/images/
      vm_count          = 1
      environment_names = toset(["test", "stage"])
    }
    production = {
      capitalized       = "Production"
      profile           = "release"
      ipv4_cidr_block   = "10.24.0.0/16"
      droplet_size      = "s-1vcpu-1gb"   // https://slugs.do-api.dev
      debian_image      = "debian-12-x64" // https://docs.digitalocean.com/products/droplets/details/images/
      vm_count          = 1
      environment_names = toset(["production"])
    }
  }
  common_tags = [
    var.project,
    local.config["capitalized"],
    "terraform"
  ]
  resource_prefix   = "${var.project}-${terraform.workspace}"
  admin_username    = "root"
  deployer_username = "deployer"
}
