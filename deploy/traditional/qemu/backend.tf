
terraform {
  backend "local" {
    path          = ".terraform.tfstate/terraform.tfstate"
    workspace_dir = ".terraform.tfstate"
  }
}
