
variable "deployment_account_id" {
  description = "The account id where to deploy the resources."
  type        = string
  sensitive   = true
}

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

locals {
  config = local.configs[terraform.workspace]
  configs = {
    sandbox = {
      capitalized       = "Sandbox"
      profile           = "debug"
      ipv4_cidr_block   = "10.20.0.0/16"
      instance_type     = "t2.micro"
      vm_count          = 1
      environment_names = ["test", "stage"]
    }
    production = {
      capitalized       = "Production"
      profile           = "release"
      ipv4_cidr_block   = "10.24.0.0/16"
      instance_type     = "t2.micro"
      vm_count          = 1
      environment_names = ["production"]
    }
  }
  common_tags = {
    project     = var.project
    environment = terraform.workspace
    created_by  = "terraform"
    owner       = var.owner
  }
  resource_prefix   = "${var.project}-${terraform.workspace}"
  admin_username    = "admin"
  deployer_username = "deployer"
}