# frozen_string_literal: true

require "faraday"

module ExportoAPI
  class Auth < Resource
    class << self
      def fetch_token(username:, password:, scope: nil, sandbox: false, adapter: Faraday.default_adapter)
        new(username: username, password: password, sandbox: sandbox, adapter: adapter).call(scope: scope)
      end

      private :new
    end

    def initialize(username:, password:, sandbox:, adapter:)
      @username = username
      @password = password
      @sandbox = sandbox
      @adapter = adapter
    end

    def call(scope: nil)
      body = {"grant_type" => "client_credentials"}
      body["scope"] = scope unless scope.nil?

      Objects::TokenResponse.new(post_request("auth/token", body: body))
    end

    private

    attr_reader :username, :password, :adapter

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = @sandbox ? Client::TEST_BASE_URL : Client::LIVE_BASE_URL
        connection.headers["Accept"] = "application/json"
        connection.request :authorization, :basic, username, password
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end
  end
end
