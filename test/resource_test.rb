# frozen_string_literal: true

require "json"
require "faraday"

require_relative "test_helper"

class ResourceTest < Minitest::Test
  class ShipmentProbeResource < ExportoAPI::Resource
    def find(id)
      get("shipments/#{id}", {include: "labels"})
    end
  end

  def test_delegates_requests_through_the_clients_injected_adapter
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/v1/shipments/123?include=labels") do
        [200, {"Content-Type" => "application/json"}, JSON.generate(id: 123)]
      end
    end
    client = ExportoAPI::Client.new(adapter: [:test, stubs])
    resource = ShipmentProbeResource.new(client)

    response = resource.find(123)

    assert_instance_of Faraday::Response, response
    assert_equal({"id" => 123}, response.body)
    stubs.verify_stubbed_calls
  end
end
