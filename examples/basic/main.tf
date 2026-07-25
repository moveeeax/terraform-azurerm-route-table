terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.112, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "route_table" {
  source = "../.."

  name                = "example-rt"
  resource_group_name = "example-rg"
  location            = "eastus"

  routes = [
    {
      name           = "default-to-firewall"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "VirtualAppliance"

      next_hop_in_ip_address = "10.0.0.4"
    }
  ]

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "route_table_id" {
  value = module.route_table.id
}
