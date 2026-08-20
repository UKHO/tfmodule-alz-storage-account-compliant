# ==============================================================================
# Terraform and Provider Requirements
# ==============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 5.0.0"
      configuration_aliases = [azurerm.hub, azurerm.oldhub]
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.9.0"
    }
  }
}
