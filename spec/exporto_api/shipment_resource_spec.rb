# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::ShipmentResource do
  subject(:shipment) { client.shipment }

  let(:access_token) { "shipment-access-token" }
  let(:client) { ExportoAPI::Client.new(access_token: access_token, sandbox: true) }

  describe "#search" do
    it "maps all supported keywords to Exporto query keys without coercion" do
      request = stub_request(:get, endpoint("shipment/search"))
        .with(
          query: {
            "foreignOutboundTrackingId" => "outbound-123",
            "foreignInboundTrackingId" => "inbound-456",
            "processedAt" => "2026-08-31T09:15:00+08:00",
            "carrierReceivedAtUpdatedAt" => "2026-08-30T10:00:00Z",
            "carrierDeliveredAtUpdatedAt" => "2026-08-31T11:00:00Z",
            "page" => "2",
            "pageSize" => "50",
            "type" => "inbound"
          }
        )
        .to_return(status: 200, body: JSON.generate([]))

      shipment.search(
        foreign_outbound_tracking_id: "outbound-123",
        foreign_inbound_tracking_id: "inbound-456",
        processed_at: "2026-08-31T09:15:00+08:00",
        carrier_received_at_updated_at: "2026-08-30T10:00:00Z",
        carrier_delivered_at_updated_at: "2026-08-31T11:00:00Z",
        page: 2,
        page_size: 50,
        type: "inbound"
      )

      expect(request).to have_been_requested.once
    end

    it "omits nil values while preserving page zero" do
      request = stub_request(:get, endpoint("shipment/search"))
        .with(query: {"foreignOutboundTrackingId" => "outbound-123", "page" => "0"})
        .to_return(status: 200, body: JSON.generate([]))

      shipment.search(foreign_outbound_tracking_id: "outbound-123", page: 0)

      expect(request).to have_been_requested.once
    end

    it "returns an empty array for no results" do
      stub_request(:get, endpoint("shipment/search"))
        .to_return(status: 200, body: JSON.generate([]))

      expect(shipment.search).to eq([])
    end

    it "maps every result with snake-case access and its original response" do
      response = [
        {
          "shipmentId" => "shipment-123",
          "foreignOutboundTrackingId" => "outbound-123",
          "lineItems" => [{"articleId" => "article-123"}]
        },
        {
          "shipmentId" => "shipment-456",
          "foreignInboundTrackingId" => "inbound-456",
          "lineItems" => [{"articleId" => "article-456"}]
        }
      ]
      stub_request(:get, endpoint("shipment/search"))
        .with(query: {"foreignOutboundTrackingId" => "outbound-123"})
        .to_return(status: 200, body: JSON.generate(response))

      shipments = shipment.search(foreign_outbound_tracking_id: "outbound-123")

      expect(shipments.map(&:class)).to eq([
        ExportoAPI::Objects::ShipmentResponse,
        ExportoAPI::Objects::ShipmentResponse
      ])
      expect(shipments.map(&:shipment_id)).to eq(["shipment-123", "shipment-456"])
      expect(shipments.map { |result| result.line_items.first.article_id })
        .to eq(["article-123", "article-456"])
      expect(shipments.map(&:raw)).to eq(response)
      expect(shipments.map(&:raw)).to all(be_frozen)
    end

    it "propagates provider validation failures" do
      stub_request(:get, endpoint("shipment/search"))
        .to_return(
          status: 400,
          body: JSON.generate("message" => "A search selector is required"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { shipment.search }.to raise_error(ExportoAPI::ValidationError)
    end

    it "propagates transport failures through APIError" do
      stub_request(:get, endpoint("shipment/search"))
        .to_raise(Faraday::ConnectionFailed.new("socket closed"))

      expect { shipment.search }
        .to raise_error(ExportoAPI::APIError) do |error|
          expect(error.message).to eq("Network request failed")
          expect(error.cause).to be_a(Faraday::ConnectionFailed)
        end
    end
  end

  describe "#find" do
    it "retrieves the exact shipment and maps its response data" do
      response = {
        "status" => "processed",
        "shipmentId" => "shipment-123",
        "orderId" => "order-123",
        "type" => "outbound",
        "lineItems" => [{"articleId" => "article-123"}]
      }
      request = stub_request(:get, endpoint("shipment/shipment-123"))
        .to_return(status: 200, body: JSON.generate(response))

      result = shipment.find(shipment_id: "shipment-123")

      expect(request).to have_been_requested.once
      expect(result).to be_a(ExportoAPI::Objects::ShipmentResponse)
      expect(result.shipment_id).to eq("shipment-123")
      expect(result.order_id).to eq("order-123")
      expect(result.line_items.first.article_id).to eq("article-123")
      expect(result.raw).to eq(response)
      expect(result.raw).to be_frozen
    end

    it "propagates a typed not-found error" do
      stub_request(:get, endpoint("shipment/missing"))
        .to_return(
          status: 404,
          body: JSON.generate("message" => "Shipment not found"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { shipment.find(shipment_id: "missing") }
        .to raise_error(ExportoAPI::NotFoundError)
    end
  end

  def endpoint(path)
    "#{ExportoAPI::Client::TEST_BASE_URL}#{path}"
  end
end
