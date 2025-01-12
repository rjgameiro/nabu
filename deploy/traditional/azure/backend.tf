
terraform {
  backend "azurerm" {
    # key                  = "projectname.tfstate"
    # resource_group_name  = "rg-projectname-azure-foundation"
    # storage_account_name = "stprojectnameazurefoundation"
    # container_name       = "projectname-azure-terraform-state"
    encrypt  = true
    use_oidc = true
  }
}
