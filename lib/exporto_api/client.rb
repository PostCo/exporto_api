# frozen_string_literal: true

require "faraday"

module ExportoAPI
  class Client
    LIVE_BASE_URL = "https://api.exporto.de/v1/"
    TEST_BASE_URL = "https://staging.api.exporto.de/v1/"

    attr_reader :adapter

    def initialize(sandbox: false, adapter: Faraday.default_adapter)
      @sandbox = sandbox
      @adapter = adapter
    end

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = sandbox? ? TEST_BASE_URL : LIVE_BASE_URL
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end

    private

    def sandbox?
      @sandbox
    end
  end
end
