# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::OrderResource do
  subject(:resource) { client.order }

  let(:access_token) { "order-access-token" }
  let(:client) { ExportoAPI::Client.new(access_token: access_token, sandbox: true) }
  let(:order_id) { "exporto-order-123" }
  let(:payload) do
    {
      "shipmentId" => "return-shipment-123",
      "foreignInboundTrackingId" => "TRACK-INBOUND-123"
    }
  end

  describe "#create_return_shipment" do
    it "posts the exact registration body once to the path-selected order" do
      request = stub_request(:post, endpoint("order/#{order_id}/return-shipment"))
        .with(
          body: JSON.generate(payload),
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}",
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 201, body: "")

      resource.create_return_shipment(order_id: order_id, payload: payload)

      expect(request).to have_been_requested.once
    end

    {
      200 => JSON.generate("undocumented" => {"data" => true}),
      201 => JSON.generate("shipmentId" => "provider-value"),
      204 => "",
      299 => "unexpected success body"
    }.each do |status, body|
      it "returns true for HTTP #{status} and ignores its response body" do
        request = stub_return_shipment_request.to_return(status: status, body: body)

        result = resource.create_return_shipment(order_id: order_id, payload: payload)

        expect(result).to be(true)
        expect(request).to have_been_requested.once
      end
    end

    {
      400 => ExportoAPI::ValidationError,
      502 => ExportoAPI::ServerError
    }.each do |status, error_class|
      it "propagates HTTP #{status} as #{error_class}" do
        request = stub_return_shipment_request.to_return(
          status: status,
          body: JSON.generate("message" => "Registration failed"),
          headers: {"Content-Type" => "application/json"}
        )

        expect do
          resource.create_return_shipment(order_id: order_id, payload: payload)
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
        resource.create_return_shipment(order_id: order_id, payload: payload)
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

  def stub_return_shipment_request
    stub_request(:post, endpoint("order/#{order_id}/return-shipment"))
      .with(body: JSON.generate(payload))
  end
end
