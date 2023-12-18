terraform {
  required_version = ">= 1.6.1"

  required_providers {

    alkira = {
      source  = "alkiranet/alkira"
      version = ">= 1.1.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.55.0"
    }

  }
}