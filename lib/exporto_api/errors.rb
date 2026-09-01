# frozen_string_literal: true

module ExportoAPI
  class Error < StandardError
    attr_reader :response, :status_code, :request_id, :retry_after

    def initialize(message = nil, response: nil, status_code: nil, request_id: nil, retry_after: nil)
      super(message)
      @response = response
      @status_code = status_code
      @request_id = request_id
      @retry_after = retry_after
    end
  end

  class APIError < Error; end

  class AuthenticationError < Error; end

  class ValidationError < Error; end

  class NotFoundError < Error; end

  class RateLimitError < Error; end

  class ServerError < Error; end
end
