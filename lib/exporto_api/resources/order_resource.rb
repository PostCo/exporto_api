# frozen_string_literal: true

module ExportoAPI
  class OrderResource < Resource
    def create_return_shipment(payload)
      post_request("order/return-shipment", body: payload)
      true
    end
  end
end
