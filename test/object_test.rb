# frozen_string_literal: true

require_relative "test_helper"

class ObjectTest < Minitest::Test
  def test_recursively_exposes_snake_case_attributes
    object = ExportoAPI::Object.new(
      "ShipmentID" => 123,
      "recipientAddress" => {"FirstName" => "Ada"},
      "parcelItems" => [{"ProductSKU" => "SKU-1"}]
    )

    assert_equal 123, object.shipment_id
    assert_equal 123, object["ShipmentID"]
    assert_equal "Ada", object.recipient_address.first_name
    assert_equal "SKU-1", object.parcel_items.first.product_sku
    assert_respond_to object, :recipient_address
  end

  def test_preserves_a_deeply_frozen_copy_of_the_original_response
    first_name = String.new("Ada")
    response = {
      "recipientAddress" => {"FirstName" => first_name},
      "events" => [{"name" => "created"}]
    }
    object = ExportoAPI::Object.new(response)

    assert_same object.raw, object.original_response
    assert_equal response, object.raw
    refute_same response, object.raw
    assert_predicate object.raw, :frozen?
    assert_predicate object.raw.fetch("recipientAddress"), :frozen?
    assert_predicate object.raw.fetch("recipientAddress").fetch("FirstName"), :frozen?
    assert_predicate object.raw.fetch("events"), :frozen?
    assert_predicate object.raw.fetch("events").first, :frozen?
    refute_predicate first_name, :frozen?

    assert_raises(FrozenError) do
      object.raw.fetch("recipientAddress")["FirstName"] = "Grace"
    end
  end
end
