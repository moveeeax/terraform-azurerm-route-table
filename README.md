# terraform-azurerm-route-table

Terraform module that manages an [Azure](https://azure.microsoft.com/) route
table. Custom routes are supplied as a list and rendered through a dynamic
block, letting you steer subnet traffic to virtual appliances, gateways or the
internet without changing the module.

## Usage

```hcl
module "route_table" {
  source = "github.com/moveeeax/terraform-azurerm-route-table"

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
| azurerm   | >= 3.112, < 5.0  |

`bgp_route_propagation_enabled` replaced the inverted
`disable_bgp_route_propagation` in azurerm 3.112.0 and is the only spelling
accepted by azurerm 4.x, hence the floor. Running the test suite additionally
needs Terraform >= 1.7 for `mock_provider`; consuming the module does not.

## Inputs

| Name                            | Description                                                     | Type           | Default | Required |
|---------------------------------|-----------------------------------------------------------------|----------------|---------|:--------:|
| `name`                          | Name of the route table.                                        | `string`       | n/a     |   yes    |
| `resource_group_name`           | Name of the resource group in which to create the route table.  | `string`       | n/a     |   yes    |
| `location`                      | Azure region in which to create the route table.                | `string`       | n/a     |   yes    |
| `bgp_route_propagation_enabled` | Whether to propagate routes learned by BGP on the route table.  | `bool`         | `true`  |    no    |
| `routes`                        | List of routes applied to the route table (see [Routes](#routes)). | `list(object)` | `[]` |    no    |
| `tags`                          | Map of tags applied to the route table.                         | `map(string)`  | `{}`    |    no    |

## Outputs

| Name      | Description                                        |
|-----------|----------------------------------------------------|
| `id`      | ID of the route table.                             |
| `name`    | Name of the route table.                           |
| `subnets` | IDs of the subnets associated with the route table.|

The module does not create subnet associations. Attach the table with
`azurerm_subnet_route_table_association` in the calling configuration; `subnets`
reports what is currently attached and is only known after apply.

## Tests

```sh
terraform test
```

The provider is mocked, so the suite needs no Azure credentials and no network
access.

## License

[MIT](LICENSE)
