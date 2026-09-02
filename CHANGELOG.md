# Changelog

## [Unreleased]

## [0.1.0] - 2026-09-02

### Added

- Rails-independent live and staging clients with injectable Faraday adapters.
- OAuth client-credentials authentication and Bearer-authenticated API requests.
- Snake-case response objects with deeply frozen access to the original provider response.
- Typed authentication, validation, not-found, rate-limit, server, and transport errors with safe metadata.
- Label-method discovery through `client.label_method.all`.
- Shipment search and retrieval through `client.shipment.search` and `client.shipment.find`.
- Label creation through `client.label.create` without automatic mutation retries.
- Return-shipment registration through `client.return_shipment.create`, returning a typed success response for every `2xx` response.

### Out of scope

- Token caching, expiry buffers, refresh, and concurrency policy remain caller responsibilities.
- Shipment deletion and carrier-label cancellation are not part of the initial public API.
