# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `subnet_ids` (map of static label to subnet ID) creates one
  `azurerm_subnet_route_table_association` per entry. Defaults to `{}`, which
  creates no associations. Values must be subnet resource IDs, and the same
  subnet may not be listed twice.
- Output `association_ids`, keyed like `subnet_ids`.

### Changed

- Docs: the `subnets` output description now says it includes associations
  made outside the module and lags behind `subnet_ids` until the next refresh.

## [1.1.0] - 2026-11-05

See the [GitHub release](https://github.com/moveeeax/terraform-azurerm-route-table/releases/tag/v1.1.0).

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-route-table/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-route-table/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-route-table/tree/v1.0.0
