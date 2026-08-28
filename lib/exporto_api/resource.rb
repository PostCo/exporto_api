# frozen_string_literal: true

module ExportoAPI
  class Resource
    def initialize(client)
      @client = client
    end

    protected

    attr_reader :client

    def get(path, params = nil, headers = nil)
      handle_response(client.connection.get(path, params, headers))
    end

    def post(path, body = nil, headers = nil)
      handle_response(client.connection.post(path, body, headers))
    end

    def put(path, body = nil, headers = nil)
      handle_response(client.connection.put(path, body, headers))
    end

    def patch(path, body = nil, headers = nil)
      handle_response(client.connection.patch(path, body, headers))
    end

    def delete(path, params = nil, headers = nil)
      handle_response(client.connection.delete(path, params, headers))
    end

    def handle_response(response)
      response
    end
  end
end
