terraform {
  required_version = "=1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.33.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.0"
    }
  }
}
