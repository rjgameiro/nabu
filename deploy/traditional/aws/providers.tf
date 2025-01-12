
terraform {
  required_version = ">= 1.8.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
    linode = {
      source  = "linode/linode"
      version = ">= 2.31.0"
    }
  }
}
