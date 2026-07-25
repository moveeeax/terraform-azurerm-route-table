terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      # bgp_route_propagation_enabled was introduced in azurerm 3.112.0 as the
      # replacement for the inverted disable_bgp_route_propagation, and is the
      # only spelling left in 4.x. Anything older resolves an incompatible
      # provider and fails `terraform validate` with "Unsupported argument".
      source  = "hashicorp/azurerm"
      version = ">= 3.112, < 5.0"
    }
  }
}
