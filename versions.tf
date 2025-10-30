# ==============================================================================
# Terraform and Provider Requirements
# ==============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 3.70"
      configuration_aliases = [azurerm.hub, azurerm.oldhub]
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}
