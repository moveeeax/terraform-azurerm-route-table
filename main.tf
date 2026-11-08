resource "azurerm_route_table" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  bgp_route_propagation_enabled = var.bgp_route_propagation_enabled

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags
}

# One association per subnet. The map keys, not the subnet IDs, form the
# resource addresses, so they must be static strings known at plan time while
# the IDs may come from subnets created in the same apply. Azure allows one
# route table per subnet, so a subnet listed here must not also be linked to a
# route table anywhere else (terraform-azurerm-subnet's route_table_id, a
# hand-written association, or the write-only route_table_id_wo that
# azurerm_subnet gained in 5.x).
resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.subnet_ids

  subnet_id      = each.value
  route_table_id = azurerm_route_table.this.id
}
