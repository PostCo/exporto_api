# frozen_string_literal: true

module ExportoAPI
  class ReturnShipmentResource < Resource
    def create(payload)
      post_request("order/return-shipment", body: payload)
      true
    end
  end
end
