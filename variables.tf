variable "name" {
  description = "Name of the route table."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the route table."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the route table."
  type        = string
}

variable "bgp_route_propagation_enabled" {
  description = "Whether to propagate routes learned by BGP on the route table. This is the inverse of the pre-4.x azurerm argument disable_bgp_route_propagation."
  type        = bool
  default     = true
}

variable "routes" {
  description = <<-EOT
    List of routes applied to the route table. address_prefix takes a CIDR block
    or an Azure service tag. next_hop_in_ip_address is required when
    next_hop_type is "VirtualAppliance" and must be omitted for every other next
    hop type.
  EOT
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.routes : try(trimspace(r.next_hop_in_ip_address), "") != ""
      if r.next_hop_type == "VirtualAppliance"
    ])
    error_message = "Routes with next_hop_type \"VirtualAppliance\" must set next_hop_in_ip_address. Azure accepts the plan and then rejects the apply."
  }

  validation {
    condition = alltrue([
      for r in var.routes : try(trimspace(r.next_hop_in_ip_address), "") == ""
      if r.next_hop_type != "VirtualAppliance"
    ])
    error_message = "next_hop_in_ip_address may only be set on routes whose next_hop_type is \"VirtualAppliance\". Azure accepts the plan and then rejects the apply."
  }

  validation {
    condition = alltrue([
      for r in var.routes :
      can(cidrhost("${r.next_hop_in_ip_address}/32", 0)) || can(cidrhost("${r.next_hop_in_ip_address}/128", 0))
      if try(trimspace(r.next_hop_in_ip_address), "") != ""
    ])
    error_message = "next_hop_in_ip_address must be a valid IPv4 or IPv6 address."
  }

  validation {
    condition = alltrue([
      for r in var.routes :
      strcontains(r.address_prefix, "/")
      ? can(cidrhost(r.address_prefix, 0))
      : can(regex("^[A-Za-z][A-Za-z0-9._-]*$", r.address_prefix))
    ])
    error_message = "address_prefix must be a valid CIDR block (for example \"0.0.0.0/0\") or an Azure service tag (for example \"AzureCloud.eastus\")."
  }
}

variable "tags" {
  description = "Map of tags applied to the route table."
  type        = map(string)
  default     = {}
}
