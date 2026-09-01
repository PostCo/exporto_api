# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::Resource do
  let(:resource_class) do
    Class.new(described_class) do
      def fetch(path, params: {}, headers: {})
        get_request(path, params: params, headers: headers)
      end

      def create(path, body:, headers: {})
        post_request(path, body: body, headers: headers)
      end
    end
  end

  subject(:resource) { resource_class.new(client) }

  let(:client) { ExportoAPI::Client.new(sandbox: true) }

  describe "successful requests" do
    it "returns JSON parsed by Faraday for a correct content type" do
      stub_request(:get, endpoint("records/123"))
        .to_return(
          status: 200,
          body: JSON.generate("recordId" => 123),
          headers: {"Content-Type" => "application/json"}
        )

      expect(resource.fetch("records/123")).to eq("recordId" => 123)
    end

    it "parses JSON with an incorrect content type" do
      stub_request(:get, endpoint("wrong-content-type"))
        .to_return(
          status: 200,
          body: JSON.generate("status" => "ok"),
          headers: {"Content-Type" => "text/plain"}
        )

      expect(resource.fetch("wrong-content-type")).to eq("status" => "ok")
    end

    it "parses JSON with no content type" do
      stub_request(:get, endpoint("missing-content-type"))
        .to_return(status: 200, body: JSON.generate("status" => "ok"))

      expect(resource.fetch("missing-content-type")).to eq("status" => "ok")
    end

    it "preserves a non-JSON body" do
      stub_request(:get, endpoint("health"))
        .to_return(status: 200, body: "healthy", headers: {"Content-Type" => "text/plain"})

      expect(resource.fetch("health")).to eq("healthy")
    end

    it "sends POST bodies and headers through the client connection" do
      payload = {"shipmentId" => "return-123"}
      stub_request(:post, endpoint("shipments"))
        .with(
          body: JSON.generate(payload),
          headers: {
            "Content-Type" => "application/json",
            "X-Request-ID" => "request-123"
          }
        )
        .to_return(status: 201, body: JSON.generate("created" => true))

      result = resource.create(
        "shipments",
        body: payload,
        headers: {"X-Request-ID" => "request-123"}
      )

      expect(result).to eq("created" => true)
    end
  end

  describe "failures" do
    it "raises ExportoAPI::Error with HTTP response context" do
      stub_request(:get, endpoint("invalid"))
        .to_return(
          status: 422,
          body: JSON.generate("message" => "Invalid shipment"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("invalid") }
        .to raise_error(ExportoAPI::Error) do |error|
          expect(error.message).to include("HTTP 422", "Invalid shipment")
          expect(error.status_code).to eq(422)
          expect(error.response.status).to eq(422)
        end
    end

    it "wraps Faraday failures and retains the original cause" do
      stub_request(:get, endpoint("unavailable"))
        .to_raise(Faraday::ConnectionFailed.new("socket closed"))

      expect { resource.fetch("unavailable") }
        .to raise_error(ExportoAPI::Error) do |error|
          expect(error.message).to include("Network error", "socket closed")
          expect(error.status_code).to be_nil
          expect(error.response).to be_nil
          expect(error.cause).to be_a(Faraday::ConnectionFailed)
        end
    end
  end

  def endpoint(path)
    "#{ExportoAPI::Client::TEST_BASE_URL}#{path}"
  end
end
