# frozen_string_literal: true

require "faraday"

module ExportoAPI
  class Client
    attr_reader :base_url, :configuration, :connection, :environment

    def initialize(sandbox: false, configuration: ExportoAPI.configuration, adapter: Faraday.default_adapter)
      @environment = sandbox ? :sandbox : :live
      @configuration = configuration
      @base_url = configuration.base_url_for(sandbox: sandbox).dup.freeze
      @connection = build_connection(adapter)
    end

    def sandbox?
      environment == :sandbox
    end

    private

    def build_connection(adapter)
      Faraday.new(url: base_url) do |connection|
        connection.request :json
        connection.response :json
        connection.adapter(*Array(adapter))
      end
    end
  end
end
