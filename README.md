# exporto_api

Rails-independent Ruby client for the Exporto API

## Usage

Create an authenticated client. Label creation accepts an Exporto-shaped payload, while return-shipment registration accepts Ruby keyword arguments:

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

client.return_shipment.create(
  order_id: "exporto-order-123",
  shipment_id: "return-shipment-123",
  foreign_inbound_tracking_id: label.tracking_code
)
```

`methodId` is account-specific and determines the carrier and shipment direction. For an inbound label, `address` is the return sender's address.

Return-shipment registration maps its Ruby keyword arguments to Exporto's request body for `POST /order/return-shipment`. Provide exactly one of `order_id` or `customer_facing_id`, together with `shipment_id` and `foreign_inbound_tracking_id`. It returns `true` for a successful `2xx` response; unsuccessful responses raise the corresponding `ExportoAPI` error.

## Development

```sh
bundle install
bundle exec rake
gem build exporto_api.gemspec
```
