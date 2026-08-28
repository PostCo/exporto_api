# frozen_string_literal: true

require "uri"

module ExportoAPI
  class Configuration
    LIVE_BASE_URL = "https://api.exporto.de/v1/"

    attr_reader :base_url, :sandbox_base_url

    def initialize(base_url: LIVE_BASE_URL, sandbox_base_url: nil)
      self.base_url = base_url
      self.sandbox_base_url = sandbox_base_url
    end

    def base_url=(value)
      @base_url = normalize_url(value, setting: "base_url")
    end

    alias live_base_url base_url
    alias live_base_url= base_url=

    def sandbox_base_url=(value)
      @sandbox_base_url = if blank?(value)
        nil
      else
        normalize_url(value, setting: "sandbox_base_url")
      end
    end

    def base_url_for(sandbox: false)
      return base_url unless sandbox

      sandbox_base_url || raise(
        ConfigurationError,
        "sandbox_base_url must be configured when sandbox mode is enabled"
      )
    end

    private

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def normalize_url(value, setting:)
      if blank?(value)
        raise ConfigurationError, "#{setting} must be a nonblank HTTP(S) URL"
      end

      uri = URI.parse(value.to_s.strip)
      unless uri.is_a?(URI::HTTP) && uri.host
        raise ConfigurationError, "#{setting} must be an absolute HTTP(S) URL"
      end

      if uri.query || uri.fragment
        raise ConfigurationError, "#{setting} cannot contain a query or fragment"
      end

      uri.path = "#{uri.path}/" unless uri.path.end_with?("/")
      uri.to_s.freeze
    rescue URI::InvalidURIError
      raise ConfigurationError, "#{setting} must be a valid URL"
    end
  end
end
