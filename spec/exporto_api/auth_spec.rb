# frozen_string_literal: true

require "json"
require "stringio"

RSpec.describe ExportoAPI::Auth do
  let(:username) { "exporto-user" }
  let(:password) { "exporto-password" }
  let(:sandbox) { false }

  describe ".fetch_token" do
    let(:token_response) do
      {
        "access_token" => "returned-access-token",
        "token_type" => "bearer",
        "expires_in" => 1800,
        "scope" => "order:write label:create"
      }
    end

    it "does not expose a public constructor" do
      expect(described_class).not_to respond_to(:new)
    end

    it "uses Basic authentication and always sends the client credentials grant" do
      request = stub_token_request(
        body: {"grant_type" => "client_credentials"}
      ).to_return(
        status: 200,
        body: JSON.generate(token_response),
        headers: {"Content-Type" => "application/json"}
      )

      fetch_token

      expect(request).to have_been_requested.once
    end

    it "uses the staging URL when sandbox mode is enabled" do
      request = stub_token_request(
        body: {"grant_type" => "client_credentials"},
        base_url: ExportoAPI::Client::TEST_BASE_URL
      ).to_return(status: 200, body: JSON.generate(token_response))

      fetch_token(sandbox: true)

      expect(request).to have_been_requested.once
    end

    it "omits scope when none is supplied" do
      request = stub_token_request(
        body: {"grant_type" => "client_credentials"}
      ).to_return(status: 200, body: JSON.generate(token_response))

      fetch_token

      expect(request).to have_been_requested.once
    end

    it "sends a supplied space-delimited scope unchanged" do
      scope = "label:create order:write shipment:read"
      request = stub_token_request(
        body: {
          "grant_type" => "client_credentials",
          "scope" => scope
        }
      ).to_return(status: 200, body: JSON.generate(token_response.merge("scope" => scope)))

      fetch_token(scope: scope)

      expect(request).to have_been_requested.once
    end

    it "maps the complete response into a token response object" do
      stub_token_request(body: {"grant_type" => "client_credentials"})
        .to_return(status: 200, body: JSON.generate(token_response))

      token = fetch_token

      expect(token).to be_a(ExportoAPI::Objects::TokenResponse)
      expect(token.access_token).to eq("returned-access-token")
      expect(token.token_type).to eq("bearer")
      expect(token.expires_in).to eq(1800)
      expect(token.scope).to eq("order:write label:create")
      expect(token.raw).to eq(token_response)
    end

    it "propagates typed authentication failures with request metadata" do
      stub_token_request(body: {"grant_type" => "client_credentials"})
        .to_return(
          status: 401,
          body: JSON.generate(
            "message" => "Unauthorized",
            "requestId" => "token-request-id"
          ),
          headers: {"Content-Type" => "application/json"}
        )

      expect { fetch_token }
        .to raise_error(ExportoAPI::AuthenticationError) do |error|
          expect(error.status_code).to eq(401)
          expect(error.request_id).to eq("token-request-id")
        end
    end

    it "does not retry or log credentials when the request times out" do
      request = stub_token_request(body: {"grant_type" => "client_credentials"})
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      error, output = capture_failure { fetch_token }

      expect(error).to be_a(ExportoAPI::TimeoutError)
      expect(request).to have_been_requested.once
      expect(output).not_to include(username, password, Faraday::Utils.basic_header_from(username, password))
    end

    it "uses an injected adapter" do
      adapter = Class.new(Faraday::Adapter) do
        def call(_environment)
          raise "injected adapter used"
        end
      end

      expect { fetch_token(adapter: adapter) }.to raise_error("injected adapter used")
    end
  end

  def fetch_token(scope: nil, sandbox: self.sandbox, adapter: Faraday.default_adapter)
    described_class.fetch_token(
      username: username,
      password: password,
      scope: scope,
      sandbox: sandbox,
      adapter: adapter
    )
  end

  def stub_token_request(body:, base_url: ExportoAPI::Client::LIVE_BASE_URL)
    stub_request(:post, "#{base_url}auth/token")
      .with(
        basic_auth: [username, password],
        body: JSON.generate(body),
        headers: {
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        }
      )
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
