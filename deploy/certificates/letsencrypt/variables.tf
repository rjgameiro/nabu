
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

variable "dns_provider" {
  description = "The type of DNS provider to use for DNS challenge.."
  type        = string
}

locals {
  config = local.configs[terraform.workspace]
  configs = {
    develop = {
      workspace_capitalized = "Develop"
      letsencrypt_staging = true
    }
    test = {
      workspace_capitalized = "Test"
      letsencrypt_staging = true
    }
    stage = {
      workspace_capitalized = "Stage"
      letsencrypt_staging = false
    }
    release = {
      workspace_capitalized = "Release"
      letsencrypt_staging = true
    }
  }
}
