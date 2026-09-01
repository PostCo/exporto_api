# frozen_string_literal: true

require "json"

module ExportoAPI
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    private

    def get_request(path, params: {}, headers: {})
      handle_response(client.connection.get(path, params, headers))
    rescue Faraday::Error => error
      raise_transport_error(error)
    end

    def post_request(path, body:, headers: {})
      handle_response(client.connection.post(path, body, headers))
    rescue Faraday::Error => error
      raise_transport_error(error)
    end

    def handle_response(response)
      body = parse_body(response.body)
      return body if response.status.between?(200, 299)

      message = "API error (HTTP #{response.status}): #{extract_error_message(body)}"
      raise Error.new(message, response: response, status_code: response.status)
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    def extract_error_message(body)
      case body
      when Hash then body["message"] || body["error"] || body.to_s
      when String then body
      else body.to_s
      end
    end

    def raise_transport_error(error)
      wrapped_error = Error.new(
        "Network error: #{error.message}",
        response: error.response,
        status_code: error.response_status
      )
      raise wrapped_error, cause: error
    end
  end
end
