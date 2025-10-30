# ==============================================================================
# Core Variables
# ==============================================================================

variable "resource_group_name" {
  description = "Name of the resource group where the storage account will be created"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault for Customer-Managed Keys (CMK) encryption"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 characters, lowercase letters and numbers only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be between 3-24 characters, lowercase letters and numbers only."
  }
}

# ==============================================================================
# Networking Variables
# ==============================================================================

variable "virtual_network_name" {
  description = "Name of the virtual network containing the subnet for private endpoints"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for private endpoints"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Resource group name of the virtual network"
  type        = string
}

# ==============================================================================
# Storage Account Configuration
# ==============================================================================

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "access_tier" {
  description = "Access tier for blob storage (Hot or Cool)"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be either Hot or Cool."
  }
}

# ==============================================================================
# Data Protection Configuration
# ==============================================================================

variable "blob_delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7

  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "Blob delete retention days must be between 1 and 365."
  }
}

variable "container_delete_retention_days" {
  description = "Number of days to retain deleted containers"
  type        = number
  default     = 7

  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365
    error_message = "Container delete retention days must be between 1 and 365."
  }
}

variable "blob_restore_days" {
  description = "Number of days for point-in-time restore capability (must be less than delete retention)"
  type        = number
  default     = 6

  validation {
    condition     = var.blob_restore_days >= 1 && var.blob_restore_days <= 364
    error_message = "Blob restore days must be between 1 and 364."
  }
}

# ==============================================================================
# Private DNS Zone Configuration - Primary (oldhub)
# ==============================================================================

variable "oldhub_dns_zone_resource_group" {
  description = "Resource group name containing the oldhub private DNS zones"
  type        = string
}

# ==============================================================================
# Private DNS Zone Configuration - Secondary (hub)
# ==============================================================================

variable "hub_dns_zone_resource_group" {
  description = "Resource group name containing the hub private DNS zones"
  type        = string
}

# ==============================================================================
# Network Access Control
# ==============================================================================

variable "public_network_access_enabled" {
  description = "Enable public network access to the storage account (if false, private endpoints should be enabled)"
  type        = bool
  default     = false
}

variable "network_rules_default_action" {
  description = "Default action for network rules (Allow or Deny)"
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_rules_default_action)
    error_message = "Network rules default action must be either Allow or Deny."
  }
}

variable "network_rules_bypass" {
  description = "Bypass network rules for Azure services (AzureServices, Logging, Metrics, None, or combination)"
  type        = list(string)
  default     = ["None"]

  validation {
    condition     = alltrue([for v in var.network_rules_bypass : contains(["AzureServices", "Logging", "Metrics", "None"], v)])
    error_message = "Valid bypass values are: AzureServices, Logging, Metrics, None."
  }
}

variable "allowed_ip_addresses" {
  description = "List of public IP addresses or CIDR ranges allowed to access the storage account"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.allowed_ip_addresses : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", ip))])
    error_message = "IP addresses must be valid IPv4 addresses or CIDR notation (e.g., 1.2.3.4 or 1.2.3.0/24)."
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account via service endpoints"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Private Endpoint Control
# ==============================================================================

variable "enable_primary_private_endpoints" {
  description = "Enable primary private endpoints (clean names, oldhub DNS zones)"
  type        = bool
  default     = true
}

variable "enable_secondary_private_endpoints" {
  description = "Enable secondary private endpoints (hub suffix, hub DNS zones for cross-subscription DNS)"
  type        = bool
  default     = false
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Purpose = "Azure Landing Zone Compliant Storage Account"
  }
}
