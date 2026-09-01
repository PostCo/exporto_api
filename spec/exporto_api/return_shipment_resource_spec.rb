# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::ReturnShipmentResource do
  subject(:resource) { client.return_shipment }

  let(:access_token) { "order-access-token" }
  let(:client) { ExportoAPI::Client.new(access_token: access_token, sandbox: true) }
  let(:order_id) { "exporto-order-123" }
  let(:shipment_id) { "return-shipment-123" }
  let(:foreign_inbound_tracking_id) { "TRACK-INBOUND-123" }
  let(:create_params) do
    {
      order_id: order_id,
      shipment_id: shipment_id,
      foreign_inbound_tracking_id: foreign_inbound_tracking_id
    }
  end
  let(:payload) do
    {
      "orderId" => order_id,
      "shipmentId" => shipment_id,
      "foreignInboundTrackingId" => foreign_inbound_tracking_id
    }
  end

  describe "#create" do
    it "maps Ruby keyword arguments to the exact provider payload" do
      request = stub_request(:post, endpoint("order/return-shipment"))
        .with(
          body: JSON.generate(payload),
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}",
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 201, body: "")

      create_return_shipment

      expect(request).to have_been_requested.once
    end

    it "maps a customer-facing order reference and omits the unused order ID" do
      customer_facing_id = "customer-order-123"
      customer_payload = {
        "customerFacingId" => customer_facing_id,
        "shipmentId" => shipment_id,
        "foreignInboundTrackingId" => foreign_inbound_tracking_id
      }
      request = stub_return_shipment_request(customer_payload)
        .to_return(status: 201, body: "")

      create_return_shipment(order_id: nil, customer_facing_id: customer_facing_id)

      expect(request).to have_been_requested.once
    end

    {
      200 => JSON.generate("undocumented" => {"data" => true}),
      201 => JSON.generate("shipmentId" => "provider-value"),
      204 => "",
      299 => "unexpected success body"
    }.each do |status, body|
      it "returns a synthetic response object for HTTP #{status} and ignores its response body" do
        request = stub_return_shipment_request.to_return(status: status, body: body)

        result = create_return_shipment

        expect(result).to be_a(ExportoAPI::Objects::ReturnShipmentResponse)
        expect(result.success).to be(true)
        expect(result.raw).to eq(success: true)
        expect(result.raw).to be_frozen
        expect(request).to have_been_requested.once
      end
    end

    {
      400 => ExportoAPI::ValidationError,
      404 => ExportoAPI::NotFoundError,
      502 => ExportoAPI::ServerError
    }.each do |status, error_class|
      it "propagates HTTP #{status} as #{error_class}" do
        request = stub_return_shipment_request.to_return(
          status: status,
          body: JSON.generate("message" => "Registration failed"),
          headers: {"Content-Type" => "application/json"}
        )

        expect do
          create_return_shipment
        end.to raise_error(error_class) do |error|
          expect(error.status_code).to eq(status)
        end
        expect(request).to have_been_requested.once
      end
    end

    it "wraps timeouts once and retains the original Faraday cause" do
      request = stub_return_shipment_request
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      expect do
        create_return_shipment
      end.to raise_error(ExportoAPI::APIError) do |error|
        expect(error.message).to eq("Network request failed")
        expect(error.cause).to be_a(Faraday::TimeoutError)
      end
      expect(request).to have_been_requested.once
    end
  end

  def endpoint(path)
    "#{ExportoAPI::Client::TEST_BASE_URL}#{path}"
  end

  def create_return_shipment(**overrides)
    resource.create(**create_params.merge(overrides))
  end

  def stub_return_shipment_request(expected_payload = payload)
    stub_request(:post, endpoint("order/return-shipment"))
      .with(body: JSON.generate(expected_payload))
  end
end
