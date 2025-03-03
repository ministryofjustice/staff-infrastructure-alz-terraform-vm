terraform {
  required_version = "=1.9.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.21.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}
