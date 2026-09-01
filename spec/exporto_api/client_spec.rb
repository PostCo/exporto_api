# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::Client do
  subject(:client) { described_class.new(access_token: access_token, sandbox: sandbox) }

  let(:access_token) { "access-token" }
  let(:sandbox) { false }

  describe "#connection" do
    it "uses the live base URL by default" do
      expect(client.connection.url_prefix.to_s).to eq(described_class::LIVE_BASE_URL)
    end

    context "when sandbox mode is enabled" do
      let(:sandbox) { true }

      it "uses the confirmed staging base URL" do
        expect(client.connection.url_prefix.to_s).to eq(described_class::TEST_BASE_URL)
      end
    end

    it "builds the connection lazily" do
      expect(client.instance_variable_defined?(:@connection)).to be(false)

      client.connection

      expect(client.instance_variable_defined?(:@connection)).to be(true)
    end

    it "memoizes the connection" do
      expect(client.connection).to be(client.connection)
    end

    it "configures JSON request and response middleware" do
      stub_request(:post, "#{described_class::LIVE_BASE_URL}echo")
        .with(
          body: JSON.generate("shipmentId" => 123),
          headers: {"Content-Type" => "application/json"}
        )
        .to_return(
          status: 200,
          body: JSON.generate("shipmentId" => 123),
          headers: {"Content-Type" => "application/json"}
        )

      response = client.connection.post("echo", shipmentId: 123)

      expect(response.body).to eq("shipmentId" => 123)
    end

    it "sends the access token using Bearer authentication" do
      request = stub_request(:get, "#{described_class::LIVE_BASE_URL}auth/test")
        .with(
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}"
          }
        )
        .to_return(status: 200, body: JSON.generate("authenticated" => true))

      client.connection.get("auth/test")

      expect(request).to have_been_requested.once
    end

    it "does not configure logging or retry middleware" do
      middleware = client.connection.builder.handlers.map { |handler| handler.klass.name }

      expect(middleware).not_to include("Faraday::Response::Logger", "Faraday::Retry::Middleware")
    end
  end

  describe "adapter injection" do
    it "uses Faraday's default adapter when none is supplied" do
      expect(client.adapter).to eq(Faraday.default_adapter)
    end

    it "configures an injected adapter" do
      client = described_class.new(access_token: access_token, adapter: :test)

      expect(client.connection.builder.adapter.klass).to eq(Faraday::Adapter::Test)
    end
  end
end
