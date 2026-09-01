# frozen_string_literal: true

module ExportoAPI
  class ShipmentResource < Resource
    def search(
      foreign_outbound_tracking_id: nil,
      foreign_inbound_tracking_id: nil,
      processed_at: nil,
      carrier_received_at_updated_at: nil,
      carrier_delivered_at_updated_at: nil,
      page: nil,
      page_size: nil,
      type: nil
    )
      params = {
        "foreignOutboundTrackingId" => foreign_outbound_tracking_id,
        "foreignInboundTrackingId" => foreign_inbound_tracking_id,
        "processedAt" => processed_at,
        "carrierReceivedAtUpdatedAt" => carrier_received_at_updated_at,
        "carrierDeliveredAtUpdatedAt" => carrier_delivered_at_updated_at,
        "page" => page,
        "pageSize" => page_size,
        "type" => type
      }.compact

      get_request("shipment/search", params: params).map do |attributes|
        Objects::ShipmentResponse.new(attributes)
      end
    end

    def find(shipment_id:)
      Objects::ShipmentResponse.new(get_request("shipment/#{shipment_id}"))
    end
  end
end
