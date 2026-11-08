output "id" {
  description = "ID of the route table."
  value       = azurerm_route_table.this.id
}

output "name" {
  description = "Name of the route table."
  value       = azurerm_route_table.this.name
}

output "subnets" {
  description = "IDs of the subnets associated with the route table, as read from Azure. Includes associations made outside this module; associations created by subnet_ids appear only after the next refresh."
  value       = azurerm_route_table.this.subnets
}

output "association_ids" {
  description = "Map of subnet route table association IDs created by the module, keyed like subnet_ids."
  value       = { for key, association in azurerm_subnet_route_table_association.this : key => association.id }
}
