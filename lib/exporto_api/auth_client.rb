# frozen_string_literal: true

require "faraday"

module ExportoAPI
  class AuthClient
    attr_reader :username, :password, :adapter, :open_timeout, :timeout

    def initialize(username:, password:, sandbox: false, adapter: Faraday.default_adapter,
      open_timeout: Client::DEFAULT_OPEN_TIMEOUT, timeout: Client::DEFAULT_TIMEOUT)
      @username = username
      @password = password
      @sandbox = sandbox
      @adapter = adapter
      @open_timeout = open_timeout
      @timeout = timeout
    end

    def token(scope: nil)
      auth.token(scope: scope)
    end

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = sandbox? ? Client::TEST_BASE_URL : Client::LIVE_BASE_URL
        connection.options.open_timeout = open_timeout
        connection.options.timeout = timeout
        connection.headers["Accept"] = "application/json"
        connection.request :authorization, :basic, username, password
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end

    private

    def auth
      @auth ||= AuthResource.new(self)
    end

    def sandbox?
      @sandbox
    end
  end
end
