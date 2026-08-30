# frozen_string_literal: true

module ExportoAPI
  class Error < StandardError
    attr_reader :response, :status_code

    def initialize(message = nil, response: nil, status_code: nil)
      super(message)
      @response = response
      @status_code = status_code
    end
  end
end
