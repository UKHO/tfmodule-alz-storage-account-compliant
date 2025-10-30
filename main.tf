# ==============================================================================
# Azure Storage Account Module - File Organization
# ==============================================================================
#
# This Terraform module creates an Azure Storage Account with ALZ compliance
# and customer-managed key encryption for all services (including queue/table).
#
# Files Organization:
# ├── main.tf                 - This file (module overview and organization)
# ├── data-sources.tf         - All data source lookups
# ├── locals.tf               - Local value calculations  
# ├── identity-rbac.tf        - User-assigned identity and RBAC assignments
# ├── key-vault-keys.tf       - Key Vault keys for customer-managed encryption
# ├── storage-account.tf      - Main storage account resource (azapi)
# ├── private-endpoints.tf    - Private endpoints for blob/file services
# ├── variables.tf            - Input variable definitions
# ├── outputs.tf              - Module outputs
# ├── versions.tf             - Provider version constraints
# └── MIGRATION-GUIDE.md      - Guide for migrating from legacy to non-legacy
#
# Key Features:
# - Full ALZ compliance with strictest security settings
# - Customer-managed key encryption for ALL services (blob, file, queue, table)
# - Dual private endpoint support (primary + secondary subscriptions)
# - User-assigned managed identity for secure key access
# - Infrastructure encryption enabled
# - ✅ Supports count, for_each, and depends_on (non-legacy module)
#
# Provider Configuration:
# This module requires providers to be configured and passed from the calling
# module. See MIGRATION-GUIDE.md for details on how to configure providers.
# ==============================================================================
