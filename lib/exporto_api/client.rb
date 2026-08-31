# frozen_string_literal: true

require "faraday"

module ExportoAPI
  class Client
    LIVE_BASE_URL = "https://api.exporto.de/v1/"
    TEST_BASE_URL = "https://staging.api.exporto.de/v1/"

    attr_reader :access_token, :adapter

    def initialize(access_token:, sandbox: false, adapter: Faraday.default_adapter)
      @access_token = access_token
      @sandbox = sandbox
      @adapter = adapter
    end

    def label_method
      @label_method ||= LabelMethodResource.new(self)
    end

    def shipment
      @shipment ||= ShipmentResource.new(self)
    end

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = sandbox? ? TEST_BASE_URL : LIVE_BASE_URL
        connection.headers["Authorization"] = "Bearer #{access_token}"
        connection.headers["Accept"] = "application/json"
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end

    def label
      @label ||= LabelResource.new(self)
    end

    def order
      @order ||= OrderResource.new(self)
    end

    private

    def sandbox?
      @sandbox
    end
  end
end
