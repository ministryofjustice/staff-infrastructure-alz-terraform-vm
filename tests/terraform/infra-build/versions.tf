terraform {
  #required_version = "=1.2.6"
  required_version = "=1.5.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.33.0"
    }
  }
}
