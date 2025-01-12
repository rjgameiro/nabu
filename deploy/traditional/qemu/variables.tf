
variable "project" {
  description = "The name of the project."
  type        = string
}

variable "domain" {
  description = "The domain name for the TXT records for let's encrypt validation."
  type        = string
}

variable "owner" {
  description = "The email of the owner of the project (for tagging purposes)."
  type        = string
  sensitive   = true
}

variable "uefi_image_path" {
  description = "The path to the UEFI image."
  type        = string
}

variable "boot_image_path" {
  description = "The path to the boot image."
  type        = string
}

locals {
  config = local.configs[terraform.workspace]
  configs = {
    local = {
      capitalized       = "Local"
      profile           = "debug"
      environment_names = ["develop"]
      vm_count          = 1
    }
    sandbox = {
      capitalized       = "Sandbox"
      profile           = "debug"
      environment_names = ["develop"]
      vm_count          = 1
    }
  }
  resource_prefix   = "${var.project}_${terraform.workspace}"
  deployer_username = "deployer"
}