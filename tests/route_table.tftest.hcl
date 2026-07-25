# Running this suite needs Terraform/OpenTofu >= 1.7 for mock_provider.
# The module itself still only requires >= 1.5 — do not raise required_version
# for the sake of the tests.

mock_provider "azurerm" {}

variables {
  name                = "test-rt"
  resource_group_name = "test-rg"
  location            = "eastus"
}

run "defaults" {
  assert {
    condition     = azurerm_route_table.this.bgp_route_propagation_enabled == true
    error_message = "BGP route propagation should default to enabled, matching the Azure platform default."
  }

  assert {
    condition     = length(azurerm_route_table.this.route) == 0
    error_message = "No routes should be created when var.routes is left at its default."
  }
}

run "virtual_appliance_route_is_accepted" {
  variables {
    routes = [
      {
        name                   = "default-to-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4"
      }
    ]
  }

  assert {
    condition     = one(azurerm_route_table.this.route).next_hop_in_ip_address == "10.0.0.4"
    error_message = "next_hop_in_ip_address should be passed through to the route block."
  }
}

run "service_tag_address_prefix_is_accepted" {
  variables {
    routes = [
      {
        name           = "storage-direct"
        address_prefix = "Storage.eastus"
        next_hop_type  = "Internet"
      }
    ]
  }

  assert {
    condition     = one(azurerm_route_table.this.route).address_prefix == "Storage.eastus"
    error_message = "Azure service tags are valid address prefixes and must not be rejected."
  }
}

run "rejects_virtual_appliance_without_next_hop_ip" {
  command = plan

  variables {
    routes = [
      {
        name           = "default-to-firewall"
        address_prefix = "0.0.0.0/0"
        next_hop_type  = "VirtualAppliance"
      }
    ]
  }

  expect_failures = [var.routes]
}

run "rejects_next_hop_ip_on_non_virtual_appliance" {
  command = plan

  variables {
    routes = [
      {
        name                   = "to-internet"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "Internet"
        next_hop_in_ip_address = "10.0.0.4"
      }
    ]
  }

  expect_failures = [var.routes]
}

run "rejects_malformed_next_hop_ip" {
  command = plan

  variables {
    routes = [
      {
        name                   = "default-to-firewall"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.256"
      }
    ]
  }

  expect_failures = [var.routes]
}

run "rejects_malformed_address_prefix" {
  command = plan

  variables {
    routes = [
      {
        name           = "bad-prefix"
        address_prefix = "10.0.0.0/99"
        next_hop_type  = "VnetLocal"
      }
    ]
  }

  expect_failures = [var.routes]
}
