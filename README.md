# exporto_api

Rails-independent Ruby client for the Exporto API

## Usage

Create an authenticated client and pass Exporto-shaped payload hashes to its resources:

```ruby
require "exporto_api"

client = ExportoAPI::Client.new(access_token: access_token)

label = client.label.create(
  "order" => {"customerFacingId" => "ORDER-123"},
  "product" => {
    "methodId" => method_id,
    "format" => "PDF"
  },
  "package" => {
    "weight" => 1_000,
    "reference" => "RETURN-123"
  },
  "address" => {
    "name" => "Return sender",
    "line1" => "1 High Street",
    "city" => "London",
    "postCode" => "SW1A 1AA",
    "countryCode" => "GB"
  }
)

client.order.create_return_shipment(
  "orderId" => "exporto-order-123",
  "shipmentId" => "return-shipment-123",
  "foreignInboundTrackingId" => label.tracking_code
)
```

`methodId` is account-specific and determines the carrier and shipment direction. For an inbound label, `address` is the return sender's address.

Return-shipment registration sends its payload unchanged to `POST /order/return-shipment`. Provide exactly one of `orderId` or `customerFacingId`, together with `shipmentId` and `foreignInboundTrackingId`. It returns `true` for a successful `2xx` response; unsuccessful responses raise the corresponding `ExportoAPI` error.

## Development

```sh
bundle install
bundle exec rake
gem build exporto_api.gemspec
```
