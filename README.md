# terraform-azurerm-route-table

Terraform module that manages an [Azure](https://azure.microsoft.com/) route
table. Custom routes are supplied as a list and rendered through a dynamic
block, letting you steer subnet traffic to virtual appliances, gateways or the
internet without changing the module.

## Usage

```hcl
module "route_table" {
  source = "github.com/moveeeax/terraform-azurerm-route-table?ref=v1.0.0"

  name                = "egress-rt"
  resource_group_name = "prod-rg"
  location            = "eastus"

  routes = [
    {
      name                   = "default-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Subnet associations

`subnet_ids` attaches the table to subnets with one
`azurerm_subnet_route_table_association` per entry:

```hcl
module "route_table" {
  source = "github.com/moveeeax/terraform-azurerm-route-table?ref=v1.2.0"

  name                = "egress-rt"
  resource_group_name = "prod-rg"
  location            = "eastus"

  subnet_ids = {
    app  = module.app_subnet.id
    data = module.data_subnet.id
  }
}
```

The keys are labels of your choice and become the resource addresses
(`azurerm_subnet_route_table_association.this["app"]`), so they must be static
strings. The values may be IDs of subnets created in the same apply. Renaming a
key destroys and recreates that association; the route is briefly missing from
the subnet while that happens.

Decide who owns each association. Azure allows one route table per subnet, so
the link must be declared in exactly one place:

- here, via `subnet_ids`, when the route table is the natural owner (one table
  shared by several subnets);
- or on the subnet side: the `route_table_id` input of
  [terraform-azurerm-subnet](https://github.com/moveeeax/terraform-azurerm-subnet),
  a hand-written `azurerm_subnet_route_table_association`, or the write-only
  `route_table_id_wo` argument that `azurerm_subnet` has in azurerm 5.x (not
  in 4.x; `route_table_id` on the subnet is read-only).

Listing a subnet here and also linking it on the subnet side (or keeping an
old hand-written association) gives two Terraform declarations for one Azure
link, and they fight over it on every apply. When moving an existing
hand-written association into the module, use a `moved` block (same
configuration) or `terraform state mv` / `import` instead of letting it be
destroyed and recreated.

## Routes

Each element of `routes` is an object:

| Field                    | Required | Notes                                                                                      |
|--------------------------|:--------:|--------------------------------------------------------------------------------------------|
| `name`                   |   yes    | Name of the route within the table.                                                          |
| `address_prefix`         |   yes    | CIDR block (`10.0.0.0/16`, `::/0`) or an Azure service tag (`Storage.eastus`).                |
| `next_hop_type`          |   yes    | One of `VirtualAppliance`, `VirtualNetworkGateway`, `VnetLocal`, `Internet`, `None`.         |
| `next_hop_in_ip_address` | see note | **Required** when `next_hop_type` is `VirtualAppliance`, and **rejected** for every other type. |

Azure enforces that last rule server side, so getting it wrong produces a clean
plan followed by a failed apply. The module validates it up front instead.

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.5           |
| azurerm   | >= 3.112, < 6.0  |

`bgp_route_propagation_enabled` replaced the inverted
`disable_bgp_route_propagation` in azurerm 3.112.0 and is the only spelling
accepted by azurerm 4.x, hence the floor. Running the test suite additionally
needs Terraform >= 1.7 for `mock_provider`; consuming the module does not.

CI validates and tests the module against the 3.112.0 floor and the latest azurerm
5.x release; 6.x is excluded until it has been tested.

## Inputs

| Name                            | Description                                                     | Type           | Default | Required |
|---------------------------------|-----------------------------------------------------------------|----------------|---------|:--------:|
| `name`                          | Name of the route table.                                        | `string`       | n/a     |   yes    |
| `resource_group_name`           | Name of the resource group in which to create the route table.  | `string`       | n/a     |   yes    |
| `location`                      | Azure region in which to create the route table.                | `string`       | n/a     |   yes    |
| `bgp_route_propagation_enabled` | Whether to propagate routes learned by BGP on the route table.  | `bool`         | `true`  |    no    |
| `routes`                        | List of routes applied to the route table (see [Routes](#routes)). | `list(object)` | `[]` |    no    |
| `tags`                          | Map of tags applied to the route table.                         | `map(string)`  | `{}`    |    no    |
| `subnet_ids`                    | Subnets to associate with the table, keyed by a static label (see [Subnet associations](#subnet-associations)). | `map(string)` | `{}` | no |

## Outputs

| Name      | Description                                        |
|-----------|----------------------------------------------------|
| `id`      | ID of the route table.                             |
| `name`    | Name of the route table.                           |
| `subnets` | IDs of the subnets associated with the route table, as read from Azure.|
| `association_ids` | Map of association IDs created by the module, keyed like `subnet_ids`. |

`subnets` reports everything currently attached, including associations made
outside the module, and is only known after apply. It is read from the route
table, which is created before its associations, so subnets added through
`subnet_ids` show up there after the next refresh; `association_ids` is
accurate immediately.

## Tests

```sh
terraform test
```

The provider is mocked, so the suite needs no Azure credentials and no network
access.

## License

[MIT](LICENSE)
