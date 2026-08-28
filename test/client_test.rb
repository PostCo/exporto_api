# frozen_string_literal: true

require "json"
require "faraday"

require_relative "test_helper"

class ClientTest < Minitest::Test
  def test_resolves_live_environment_by_default
    client = build_client

    assert_equal :live, client.environment
    refute client.sandbox?
    assert_equal "https://api.exporto.de/v1/", client.base_url
  end

  def test_resolves_configured_sandbox_environment
    configuration = ExportoAPI::Configuration.new(
      sandbox_base_url: "https://sandbox.example.test/v1"
    )
    client = build_client(sandbox: true, configuration: configuration)

    assert_equal :sandbox, client.environment
    assert client.sandbox?
    assert_equal "https://sandbox.example.test/v1/", client.base_url
  end

  def test_missing_sandbox_configuration_raises_before_faraday_builds_a_connection
    configuration = ExportoAPI::Configuration.new
    adapter = Object.new
    adapter.define_singleton_method(:to_ary) do
      raise "Faraday connection should not be built"
    end

    assert_raises(ExportoAPI::ConfigurationError) do
      ExportoAPI::Client.new(sandbox: true, configuration: configuration, adapter: adapter)
    end
  end

  def test_client_retains_its_resolved_url_when_configuration_changes
    configuration = ExportoAPI::Configuration.new
    client = build_client(configuration: configuration)

    configuration.base_url = "https://replacement.example.test/v1"

    assert_equal "https://api.exporto.de/v1/", client.base_url
    assert_equal "https://api.exporto.de/v1/", client.connection.url_prefix.to_s
  end

  def test_injected_test_adapter_uses_json_request_and_response_middleware
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/v1/echo") do |environment|
        assert_equal "application/json", environment.request_headers["Content-Type"]
        assert_equal({"shipmentId" => 123}, JSON.parse(environment.body))

        [200, {"Content-Type" => "application/json"}, JSON.generate(shipmentId: 123)]
      end
    end
    client = ExportoAPI::Client.new(adapter: [:test, stubs])

    response = client.connection.post("echo", shipmentId: 123)

    assert_equal({"shipmentId" => 123}, response.body)
    stubs.verify_stubbed_calls
  end

  private

  def build_client(**arguments)
    stubs = Faraday::Adapter::Test::Stubs.new
    ExportoAPI::Client.new(**arguments, adapter: [:test, stubs])
  end
end
