# frozen_string_literal: true

module ExportoAPI
  class LabelMethodResource < Resource
    def all
      Objects::LabelMethodResponse.from_response(get_request("label/methods"))
    end
  end
end
