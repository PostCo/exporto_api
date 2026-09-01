# frozen_string_literal: true

require "json"

RSpec.describe ExportoAPI::Base do
  describe "response access" do
    it "recursively exposes snake-case methods for hashes and arrays" do
      object = described_class.new(
        "ShipmentID" => 123,
        "recipientAddress" => {"FirstName" => "Ada"},
        "parcelItems" => [{"ProductSKU" => "SKU-1"}]
      )

      expect(object.shipment_id).to eq(123)
      expect(object.recipient_address.first_name).to eq("Ada")
      expect(object.parcel_items.first.product_sku).to eq("SKU-1")
    end
  end

  describe "#raw" do
    it "returns a deeply frozen original response" do
      recipient_key = +"recipientAddress"
      first_name = +"Ada"
      event_name = +"created"
      events = [{"name" => event_name}]
      response = {
        recipient_key => {"FirstName" => first_name},
        "events" => events
      }
      object = described_class.new(response)

      expect(object.raw).to be(object.original_response)
      expect(object.raw).to eq(response)
      expect(object.raw).not_to be(response)
      expect(object.raw).to be_frozen
      expect(object.raw.keys.first).to be_frozen
      expect(object.raw.fetch("recipientAddress")).to be_frozen
      expect(object.raw.dig("recipientAddress", "FirstName")).to be_frozen
      expect(object.raw.fetch("events")).to be_frozen
      expect(object.raw.fetch("events").first).to be_frozen

      expect(response).not_to be_frozen
      expect(response.fetch("recipientAddress")).not_to be_frozen
      expect(recipient_key).not_to be_frozen
      expect(events).not_to be_frozen
      expect(events.first).not_to be_frozen
      expect(first_name).to be_frozen
      expect(event_name).to be_frozen
      expect(object.raw.dig("recipientAddress", "FirstName")).to be(first_name)
      expect(object.raw.dig("events", 0, "name")).to be(event_name)
    end
  end

  describe "hash conversion" do
    let(:object) do
      described_class.new(
        "returnResponse" => [
          {
            "orderid" => "RMA123",
            "returns" => [
              {"SKU" => "SKU-1", "samplingType" => "GOOD"}
            ]
          }
        ]
      )
    end

    let(:expected_hash) do
      {
        "return_response" => [
          {
            "orderid" => "RMA123",
            "returns" => [
              {"sku" => "SKU-1", "sampling_type" => "GOOD"}
            ]
          }
        ]
      }
    end

    it "makes #to_h and #to_hash equivalent recursive conversions" do
      expect(object.to_h).to eq(expected_hash)
      expect(object.to_hash).to eq(expected_hash)
      expect(object.to_h).to eq(object.to_hash)
    end

    it "does not leak nested OpenStructs" do
      expect(contains_ostruct?(object.to_h)).to be(false)
      expect(contains_ostruct?(object.to_hash)).to be(false)
    end

    it "regresses PC-8620 without internal table wrappers" do
      serialized = JSON.generate(object.to_h)

      expect(serialized).not_to include('"table"')
      expect(JSON.parse(serialized)).to eq(expected_hash)
    end
  end

  def contains_ostruct?(value)
    case value
    when OpenStruct
      true
    when Hash
      value.any? { |key, entry| contains_ostruct?(key) || contains_ostruct?(entry) }
    when Array
      value.any? { |entry| contains_ostruct?(entry) }
    else
      false
    end
  end
end
