# frozen_string_literal: true

require "json"
require "stringio"

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

  let(:access_token) { "resource-access-token" }
  let(:client) { ExportoAPI::Client.new(access_token: access_token, sandbox: true) }

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

  describe "HTTP failures" do
    {
      400 => [ExportoAPI::ValidationError, "Bad request"],
      401 => [ExportoAPI::AuthenticationError, "Authentication failed"],
      403 => [ExportoAPI::AuthenticationError, "Authentication failed"],
      404 => [ExportoAPI::NotFoundError, "Resource not found"],
      429 => [ExportoAPI::RateLimitError, "Rate limited"],
      500 => [ExportoAPI::ServerError, "Server error"],
      502 => [ExportoAPI::ServerError, "Server error"],
      504 => [ExportoAPI::ServerError, "Server error"],
      422 => [ExportoAPI::APIError, "API error"]
    }.each do |status, (error_class, prefix)|
      it "maps HTTP #{status} to #{error_class}" do
        stub_request(:get, endpoint("failure"))
          .to_return(
            status: status,
            body: JSON.generate("message" => "Provider failure"),
            headers: {"Content-Type" => "application/json"}
          )

        expect { resource.fetch("failure") }
          .to raise_error(error_class) do |error|
            expect(error.message).to eq("#{prefix} (HTTP #{status}): Provider failure")
            expect(error.status_code).to eq(status)
            expect(error.response.status).to eq(status)
          end
      end
    end

    it "prefers the request ID response header over the response body" do
      stub_request(:get, endpoint("invalid"))
        .to_return(
          status: 400,
          body: JSON.generate("message" => "Invalid shipment", "requestId" => "body-request-id"),
          headers: {
            "Content-Type" => "application/json",
            "X-Request-ID" => "header-request-id"
          }
        )

      expect { resource.fetch("invalid") }
        .to raise_error(ExportoAPI::ValidationError) do |error|
          expect(error.request_id).to eq("header-request-id")
        end
    end

    it "falls back to the request ID in the response body" do
      stub_request(:get, endpoint("unauthorized"))
        .to_return(
          status: 401,
          body: JSON.generate("message" => "Unauthorized", "requestId" => "body-request-id"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("unauthorized") }
        .to raise_error(ExportoAPI::AuthenticationError) do |error|
          expect(error.request_id).to eq("body-request-id")
        end
    end

    it "exposes retry-after as integer seconds" do
      stub_request(:get, endpoint("rate-limited"))
        .to_return(
          status: 429,
          body: JSON.generate("message" => "Too many requests"),
          headers: {
            "Content-Type" => "application/json",
            "Retry-After" => "17"
          }
        )

      expect { resource.fetch("rate-limited") }
        .to raise_error(ExportoAPI::RateLimitError) do |error|
          expect(error.retry_after).to eq(17)
        end
    end

    it "does not interpolate unapproved structured response fields into the message" do
      stub_request(:get, endpoint("unsafe-error"))
        .to_return(
          status: 500,
          body: JSON.generate("access_token" => access_token, "authorization" => "Bearer #{access_token}"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { resource.fetch("unsafe-error") }
        .to raise_error(ExportoAPI::ServerError) do |error|
          expect(error.message).to eq("Server error (HTTP 500): Unknown error")
          expect(error.message).not_to include(access_token, "Authorization")
        end
    end
  end

  describe "transport failures" do
    it "maps Faraday timeouts and retains the original cause" do
      stub_request(:get, endpoint("slow"))
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      expect { resource.fetch("slow") }
        .to raise_error(ExportoAPI::TimeoutError) do |error|
          expect(error.message).to eq("Request timed out: execution expired")
          expect(error.status_code).to be_nil
          expect(error.response).to be_nil
          expect(error.cause).to be_a(Faraday::TimeoutError)
        end
    end

    it "maps connection failures and retains the original cause" do
      stub_request(:get, endpoint("unavailable"))
        .to_raise(Faraday::ConnectionFailed.new("socket closed"))

      expect { resource.fetch("unavailable") }
        .to raise_error(ExportoAPI::ConnectionError) do |error|
          expect(error.message).to eq("Connection failed: socket closed")
          expect(error.status_code).to be_nil
          expect(error.response).to be_nil
          expect(error.cause).to be_a(Faraday::ConnectionFailed)
        end
    end

    it "maps other Faraday failures to the generic API error" do
      stub_request(:get, endpoint("broken"))
        .to_raise(Faraday::Error.new("unexpected transport failure"))

      expect { resource.fetch("broken") }
        .to raise_error(ExportoAPI::APIError) do |error|
          expect(error.message).to eq("Network error: unexpected transport failure")
          expect(error.cause).to be_a(Faraday::Error)
        end
    end

    it "does not retry or log a failed mutating request" do
      request = stub_request(:post, endpoint("shipments"))
        .with(headers: {"Authorization" => "Bearer #{access_token}"})
        .to_raise(Faraday::ConnectionFailed.new("socket closed"))

      error, output = capture_failure do
        resource.create("shipments", body: {"shipmentId" => "return-123"})
      end

      expect(error).to be_a(ExportoAPI::ConnectionError)
      expect(request).to have_been_requested.once
      expect(output).not_to include(access_token, "Bearer #{access_token}")
    end
  end

  def endpoint(path)
    "#{ExportoAPI::Client::TEST_BASE_URL}#{path}"
  end

  def capture_failure
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr
    error = nil

    begin
      $stdout = stdout
      $stderr = stderr
      yield
    rescue ExportoAPI::Error => caught_error
      error = caught_error
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    [error, stdout.string + stderr.string]
  end
end
