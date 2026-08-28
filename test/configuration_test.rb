# frozen_string_literal: true

require_relative "test_helper"

class ConfigurationTest < Minitest::Test
  def test_uses_the_live_url_when_sandbox_is_omitted_or_false
    configuration = ExportoAPI::Configuration.new

    assert_equal "https://api.exporto.de/v1/", configuration.base_url_for
    assert_equal "https://api.exporto.de/v1/", configuration.base_url_for(sandbox: false)
  end

  def test_uses_and_normalizes_a_configured_sandbox_url
    configuration = ExportoAPI::Configuration.new(
      sandbox_base_url: "  https://sandbox.example.test/v1  "
    )

    assert_equal "https://sandbox.example.test/v1/", configuration.base_url_for(sandbox: true)
  end

  def test_missing_or_blank_sandbox_url_fails_closed
    [nil, "", "   "].each do |sandbox_base_url|
      configuration = ExportoAPI::Configuration.new(sandbox_base_url: sandbox_base_url)

      error = assert_raises(ExportoAPI::ConfigurationError) do
        configuration.base_url_for(sandbox: true)
      end
      assert_match(/sandbox_base_url/, error.message)
    end
  end

  def test_live_override_does_not_supply_a_sandbox_url
    configuration = ExportoAPI::Configuration.new(base_url: "https://live.example.test/api/v1")

    assert_equal "https://live.example.test/api/v1/", configuration.base_url_for
    assert_raises(ExportoAPI::ConfigurationError) do
      configuration.base_url_for(sandbox: true)
    end
  end

  def test_rejects_non_http_base_urls
    assert_raises(ExportoAPI::ConfigurationError) do
      ExportoAPI::Configuration.new(base_url: "api.exporto.de/v1")
    end
  end
end
