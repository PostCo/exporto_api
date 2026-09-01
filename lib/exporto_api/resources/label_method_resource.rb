# frozen_string_literal: true

module ExportoAPI
  class LabelMethodResource < Resource
    def all
      Objects::LabelMethodResponse.new(get_request("label/methods"))
    end
  end
end
