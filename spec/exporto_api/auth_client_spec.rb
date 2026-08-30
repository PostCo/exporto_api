# frozen_string_literal: true

require "json"
require "stringio"

RSpec.describe ExportoAPI::AuthClient do
  subject(:auth_client) do
    described_class.new(
      username: username,
      password: password,
      sandbox: sandbox
    )
  end

  let(:username) { "exporto-user" }
  let(:password) { "exporto-password" }
  let(:sandbox) { false }

  describe "#connection" do
    it "uses the live base URL by default" do
      expect(auth_client.connection.url_prefix.to_s).to eq(ExportoAPI::Client::LIVE_BASE_URL)
    end

    context "when sandbox mode is enabled" do
      let(:sandbox) { true }

      it "uses the same staging base URL as the normal client" do
        client = ExportoAPI::Client.new(access_token: "token", sandbox: true)

        expect(auth_client.connection.url_prefix).to eq(client.connection.url_prefix)
      end
    end

    it "builds the connection lazily" do
      expect(auth_client.instance_variable_defined?(:@connection)).to be(false)

      auth_client.connection

      expect(auth_client.instance_variable_defined?(:@connection)).to be(true)
    end

    it "memoizes the connection" do
      expect(auth_client.connection).to be(auth_client.connection)
    end

    it "does not configure logging or retry middleware" do
      middleware = auth_client.connection.builder.handlers.map { |handler| handler.klass.name }

      expect(middleware).not_to include("Faraday::Response::Logger", "Faraday::Retry::Middleware")
    end
  end

  describe "#token" do
    let(:token_response) do
      {
        "access_token" => "returned-access-token",
        "token_type" => "bearer",
        "expires_in" => 1800,
        "scope" => "label:create shipment:read"
      }
    end

    it "uses Basic authentication and always sends the client credentials grant" do
      request = stub_token_request(
        body: {"grant_type" => "client_credentials"}
      ).to_return(
        status: 200,
        body: JSON.generate(token_response),
        headers: {"Content-Type" => "application/json"}
      )

      auth_client.token

      expect(request).to have_been_requested.once
    end

    it "omits scope when none is supplied" do
      request = stub_token_request(
        body: {"grant_type" => "client_credentials"}
      ).to_return(status: 200, body: JSON.generate(token_response))

      auth_client.token

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

      auth_client.token(scope: scope)

      expect(request).to have_been_requested.once
    end

    it "maps the complete response into a token response object" do
      stub_token_request(body: {"grant_type" => "client_credentials"})
        .to_return(status: 200, body: JSON.generate(token_response))

      token = auth_client.token

      expect(token).to be_a(ExportoAPI::Objects::TokenResponse)
      expect(token.access_token).to eq("returned-access-token")
      expect(token.token_type).to eq("bearer")
      expect(token.expires_in).to eq(1800)
      expect(token.scope).to eq("label:create shipment:read")
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

      expect { auth_client.token }
        .to raise_error(ExportoAPI::AuthenticationError) do |error|
          expect(error.status_code).to eq(401)
          expect(error.request_id).to eq("token-request-id")
        end
    end

    it "does not retry or log credentials when the request times out" do
      request = stub_token_request(body: {"grant_type" => "client_credentials"})
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      error, output = capture_failure { auth_client.token }

      expect(error).to be_a(ExportoAPI::TimeoutError)
      expect(request).to have_been_requested.once
      expect(output).not_to include(username, password, Faraday::Utils.basic_header_from(username, password))
    end
  end

  describe "adapter injection" do
    it "uses Faraday's default adapter when none is supplied" do
      expect(auth_client.adapter).to eq(Faraday.default_adapter)
    end

    it "configures an injected adapter" do
      client = described_class.new(username: username, password: password, adapter: :test)

      expect(client.connection.builder.adapter.klass).to eq(Faraday::Adapter::Test)
    end
  end

  def stub_token_request(body:)
    stub_request(:post, "#{ExportoAPI::Client::LIVE_BASE_URL}auth/token")
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
