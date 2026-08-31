# frozen_string_literal: true

module ExportoAPI
  class OrderResource < Resource
    def create_return_shipment(order_id:, payload:)
      post_request("order/#{order_id}/return-shipment", body: payload)
      true
    end
  end
end
