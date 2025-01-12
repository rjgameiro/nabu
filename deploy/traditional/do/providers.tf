
terraform {
  required_version = ">= 1.8.8"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
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
