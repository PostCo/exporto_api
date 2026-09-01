# frozen_string_literal: true

module ExportoAPI
  class ReturnShipmentResource < Resource
    def create(
      shipment_id:,
      foreign_inbound_tracking_id:,
      order_id: nil,
      customer_facing_id: nil
    )
      body = {
        "orderId" => order_id,
        "customerFacingId" => customer_facing_id,
        "shipmentId" => shipment_id,
        "foreignInboundTrackingId" => foreign_inbound_tracking_id
      }.compact

      post_request("order/return-shipment", body: body)

      # Exporto returns no response body for a successful return-shipment registration.
      Objects::ReturnShipmentResponse.new(success: true)
    end
  end
end
