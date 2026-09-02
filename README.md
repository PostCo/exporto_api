# ExportoAPI

Rails-independent Ruby client for the Exporto API.

## Installation

Add to your Gemfile:

```ruby
gem "exporto_api", "~> 0.1.0"
```

Then run `bundle install`.

## Usage

### Initialize clients

Exporto uses a separate OAuth client to issue an access token. Set the environment once and pass the same `sandbox:` value to both clients so the token is used only in the environment that issued it.

```ruby
require "exporto_api"

sandbox = true # Use Exporto's staging environment

auth_client = ExportoAPI::AuthClient.new(
  username: "EXPORTO_USERNAME",
  password: "EXPORTO_PASSWORD",
  sandbox: sandbox
)

token = auth_client.token

client = ExportoAPI::Client.new(
  access_token: token.access_token,
  sandbox: sandbox
)
```

`AuthClient#token` also accepts an optional space-delimited `scope:` string. Its response exposes `access_token`, `token_type`, `expires_in`, and `scope`.

The gem does not cache or refresh tokens. The caller owns token caching by Exporto account, environment, and requested scope, using the returned `expires_in` value and an application-defined safety buffer.

### List label methods

```ruby
label_methods = client.label_method.all

label_methods.each do |method|
  puts [method.method_id, method.name, method.direction, method.carrier_name]
end
```

The gem returns every method available to the authenticated account. The caller is responsible for selecting an approved method.

### Search shipments

```ruby
shipments = client.shipment.search(
  type: "outbound",
  foreign_outbound_tracking_id: "OUTBOUND-TRACKING-ID",
  page: 0,
  page_size: 50
)
```

Shipment search also accepts `foreign_inbound_tracking_id`, `processed_at`, `carrier_received_at_updated_at`, and `carrier_delivered_at_updated_at`.

### Retrieve a shipment

```ruby
shipment = client.shipment.find(shipment_id: "EXPORTO-SHIPMENT-ID")

puts shipment.shipment_id
puts shipment.order_id
puts shipment.status
puts shipment.carrier_state
```

### Create a label

Pass an Exporto-shaped payload to `client.label.create`:

```ruby
label = client.label.create(
  "order" => {"customerFacingId" => "ORDER-123"},
  "product" => {
    "methodId" => 123,
    "format" => "PDF"
  },
  "package" => {
    "weight" => 1_000,
    "reference" => "RETURN-123"
  },
  "address" => {
    "name" => "Return Sender",
    "line1" => "1 Example Street",
    "city" => "London",
    "postCode" => "SW1A 1AA",
    "countryCode" => "GB",
    "email" => "sender@example.com"
  }
)

puts label.carrier_name
puts label.tracking_code
puts label.tracking_url
```

For an inbound label, `address` is the return sender's address. The account-specific `methodId` determines the carrier and shipment direction.

### Register a return shipment

```ruby
registration = client.return_shipment.create(
  order_id: "EXPORTO-ORDER-ID",
  shipment_id: "POSTCO-GENERATED-SHIPMENT-ID",
  foreign_inbound_tracking_id: label.tracking_code
)

registration.success # => true
```

Return-shipment registration maps its Ruby keyword arguments to Exporto's request body for `POST /order/return-shipment`. Provide exactly one of `order_id` or `customer_facing_id`, together with `shipment_id` and `foreign_inbound_tracking_id`. Because Exporto returns no response body for this operation, a successful `2xx` response returns an `ExportoAPI::Objects::ReturnShipmentResponse` with `success: true`; unsuccessful responses raise the corresponding `ExportoAPI` error.

The gem does not automatically retry mutating requests. The caller owns idempotency, persistence, retry, and reconciliation policy.

### Response objects

Response objects expose Exporto's camel-case keys through snake-case Ruby methods, including nested hashes and arrays. The original provider response remains available as a deeply frozen snapshot through `raw`.

```ruby
shipment.shipment_id
shipment.line_items.first.article_id
shipment.raw
shipment.raw.frozen? # => true
```

### Error handling

HTTP failures raise typed subclasses of `ExportoAPI::Error`:

```ruby
begin
  client.shipment.find(shipment_id: "EXPORTO-SHIPMENT-ID")
rescue ExportoAPI::AuthenticationError => error
  # 401/403 responses
  puts error.message
rescue ExportoAPI::ValidationError => error
  # 400 responses
  puts error.message
rescue ExportoAPI::NotFoundError => error
  # 404 responses
  puts error.message
rescue ExportoAPI::RateLimitError => error
  # 429 responses
  puts error.retry_after
rescue ExportoAPI::ServerError => error
  # 500-599 responses
  puts error.message
rescue ExportoAPI::APIError => error
  # Other HTTP and transport failures
  puts error.message
end
```

Errors retain safe metadata where available through `status_code`, `request_id`, and `retry_after`. Transport failures retain the original Faraday exception as their cause.

### Sandbox mode

Both clients use Exporto's live environment by default. Set `sandbox: true` for staging, and always use the same value for token creation and authenticated requests:

```ruby
sandbox = false # Live: https://api.exporto.de/v1/
# sandbox = true # Staging: https://staging.api.exporto.de/v1/
```

## Development

```sh
bundle install
bundle exec rspec
bundle exec standardrb
gem build exporto_api.gemspec
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
