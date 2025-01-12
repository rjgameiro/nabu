
terraform {
  required_version = ">= 1.8.7"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = ">= 2.31.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = ">= 2.27.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
  }
}
