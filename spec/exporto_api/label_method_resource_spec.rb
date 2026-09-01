# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::LabelMethodResource do
  subject(:label_method) { client.label_method }

  let(:access_token) { "label-method-access-token" }
  let(:client) { ExportoAPI::Client.new(access_token: access_token, sandbox: true) }

  describe "#all" do
    it "performs a Bearer-authenticated request to the label methods endpoint" do
      request = stub_request(:get, endpoint)
        .with(
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}"
          }
        )
        .to_return(status: 200, body: JSON.generate([]))

      label_method.all

      expect(request).to have_been_requested.once
    end

    it "returns an empty array unchanged" do
      stub_request(:get, endpoint).to_return(status: 200, body: JSON.generate([]))

      expect(label_method.all).to eq([])
    end

    it "maps every returned method without selecting one for the caller" do
      response = [
        {
          "direction" => "OUTBOUND",
          "carrierName" => "DHL",
          "methodId" => 685,
          "name" => "DHL Paket"
        },
        {
          "direction" => "INBOUND",
          "carrierName" => "DHL",
          "methodId" => 686,
          "name" => "DHL Retoure"
        }
      ]
      stub_request(:get, endpoint).to_return(status: 200, body: JSON.generate(response))

      methods = label_method.all

      expect(methods.map(&:class)).to eq([
        ExportoAPI::Objects::LabelMethodResponse,
        ExportoAPI::Objects::LabelMethodResponse
      ])
      expect(methods.map(&:method_id)).to eq([685, 686])
      expect(methods.map(&:carrier_name)).to eq(["DHL", "DHL"])
      expect(methods.map(&:raw)).to eq(response)
      expect(methods.map(&:raw)).to all(be_frozen)
    end

    it "propagates typed API errors" do
      stub_request(:get, endpoint)
        .to_return(
          status: 401,
          body: JSON.generate("message" => "Unauthorized"),
          headers: {"Content-Type" => "application/json"}
        )

      expect { label_method.all }.to raise_error(ExportoAPI::AuthenticationError)
    end
  end

  def endpoint
    "#{ExportoAPI::Client::TEST_BASE_URL}label/methods"
  end
end
