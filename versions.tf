# ==============================================================================
# Provider Configuration
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70"
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

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  subscription_id            = var.subscription_id
  storage_use_azuread        = true
  skip_provider_registration = true
}

provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id            = var.hub_subscription_id
  skip_provider_registration = true
}

provider "azurerm" {
  alias = "oldhub"
  features {}
  subscription_id            = var.oldhub_subscription_id
  skip_provider_registration = true
}
