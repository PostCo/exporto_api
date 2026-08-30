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
      handle_response(connection.get(path, params, headers))
    rescue Faraday::Error => error
      raise_transport_error(error)
    end

    def post_request(path, body:, headers: {})
      handle_response(connection.post(path, body, headers))
    rescue Faraday::Error => error
      raise_transport_error(error)
    end

    def connection
      client.connection
    end

    def handle_response(response)
      body = parse_body(response.body)
      return body if response.status.between?(200, 299)

      error_class, prefix = error_mapping(response.status)
      message = "#{prefix} (HTTP #{response.status}): #{extract_error_message(body)}"
      raise error_class.new(
        message,
        response: response,
        status_code: response.status,
        request_id: extract_request_id(response, body),
        retry_after: extract_retry_after(response)
      )
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    def extract_error_message(body)
      case body
      when Hash then body["message"] || body[:message] || body["error"] || body[:error] || "Unknown error"
      when String then body
      else "Unknown error"
      end
    end

    def error_mapping(status)
      case status
      when 400 then [ValidationError, "Bad request"]
      when 401, 403 then [AuthenticationError, "Authentication failed"]
      when 404 then [NotFoundError, "Resource not found"]
      when 429 then [RateLimitError, "Rate limited"]
      when 500..599 then [ServerError, "Server error"]
      else [APIError, "API error"]
      end
    end

    def extract_request_id(response, body)
      response.headers["x-request-id"] || request_id_from(body)
    end

    def request_id_from(body)
      return unless body.is_a?(Hash)

      body["requestId"] || body[:requestId] || body["request_id"] || body[:request_id]
    end

    def extract_retry_after(response)
      Integer(response.headers["retry-after"], exception: false)
    end

    def raise_transport_error(error)
      error_class, prefix = transport_error_mapping(error)
      wrapped_error = error_class.new(
        "#{prefix}: #{error.message}",
        response: error.response,
        status_code: error.response_status
      )
      raise wrapped_error, cause: error
    end

    def transport_error_mapping(error)
      case error
      when Faraday::TimeoutError then [TimeoutError, "Request timed out"]
      when Faraday::ConnectionFailed then [ConnectionError, "Connection failed"]
      else [APIError, "Network error"]
      end
    end
  end
end
