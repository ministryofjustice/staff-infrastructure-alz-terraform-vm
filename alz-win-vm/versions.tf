terraform {
  required_version = ">=1.2.6"
  experiments      = [module_variable_optional_attrs]
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.33.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.3.0"
    }
  }
}