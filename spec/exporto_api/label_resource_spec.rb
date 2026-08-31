# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::LabelResource do
  subject(:resource) { client.label }

  let(:access_token) { "label-access-token" }
  let(:client) { ExportoAPI::Client.new(access_token: access_token, sandbox: true) }
  let(:payload) do
    {
      "order" => {"customerFacingId" => "ORDER-123"},
      "product" => {
        "methodId" => 234,
        "format" => "PDF"
      },
      "package" => {
        "weight" => 2345,
        "reference" => "RETURN-123"
      },
      "address" => {
        "name" => "Alexa Konstanzia",
        "line1" => "Karl Johans gate 47",
        "line2" => "Apartment 12",
        "city" => "Oslo",
        "postCode" => "0154",
        "countryCode" => "NO",
        "email" => "alexa@example.com",
        "phone" => "+472834703"
      }
    }
  end
  let(:label_response) do
    {
      "carrierName" => "DHL",
      "label" => "base64-encoded-pdf",
      "trackingCode" => "TRACK-123",
      "trackingUrl" => "https://carrier.example/track/TRACK-123"
    }
  end

  describe "#create" do
    it "posts the exact provider payload once with Bearer authentication" do
      request = stub_request(:post, endpoint("label"))
        .with(
          body: JSON.generate(payload),
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}",
            "Content-Type" => "application/json"
          }
        )
        .to_return(
          status: 201,
          body: JSON.generate(label_response),
          headers: {"Content-Type" => "application/json"}
        )

      resource.create(payload)

      expect(request).to have_been_requested.once
    end

    it "maps the provider response and retains a frozen raw response" do
      stub_label_request.to_return(
        status: 201,
        body: JSON.generate(label_response),
        headers: {"Content-Type" => "application/json"}
      )

      response = resource.create(payload)

      expect(response).to be_a(ExportoAPI::Objects::LabelResponse)
      expect(response.carrier_name).to eq("DHL")
      expect(response.label).to eq("base64-encoded-pdf")
      expect(response.tracking_code).to eq("TRACK-123")
      expect(response.tracking_url).to eq("https://carrier.example/track/TRACK-123")
      expect(response.raw).to eq(label_response)
      expect(response.raw).to be_frozen
    end

    {
      400 => ExportoAPI::ValidationError,
      503 => ExportoAPI::ServerError
    }.each do |status, error_class|
      it "propagates HTTP #{status} as #{error_class}" do
        request = stub_label_request.to_return(
          status: status,
          body: JSON.generate("message" => "Label creation failed"),
          headers: {"Content-Type" => "application/json"}
        )

        expect { resource.create(payload) }
          .to raise_error(error_class) do |error|
            expect(error.status_code).to eq(status)
          end
        expect(request).to have_been_requested.once
      end
    end

    it "wraps timeouts once and retains the original Faraday cause" do
      request = stub_label_request
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      expect { resource.create(payload) }
        .to raise_error(ExportoAPI::APIError) do |error|
          expect(error.message).to eq("Network request failed")
          expect(error.cause).to be_a(Faraday::TimeoutError)
        end
      expect(request).to have_been_requested.once
    end
  end

  def endpoint(path)
    "#{ExportoAPI::Client::TEST_BASE_URL}#{path}"
  end

  def stub_label_request
    stub_request(:post, endpoint("label"))
      .with(body: JSON.generate(payload))
  end
end
