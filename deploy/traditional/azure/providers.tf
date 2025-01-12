
terraform {
  required_version = ">= 1.8.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.7.0"
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
