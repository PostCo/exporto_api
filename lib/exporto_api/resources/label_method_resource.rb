# frozen_string_literal: true

module ExportoAPI
  class LabelMethodResource < Resource
    def all
      get_request("label/methods").map do |attributes|
        Objects::LabelMethodResponse.new(attributes)
      end
    end
  end
end
