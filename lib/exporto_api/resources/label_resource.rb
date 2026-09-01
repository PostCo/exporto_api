# frozen_string_literal: true

module ExportoAPI
  class LabelResource < Resource
    def create(payload)
      Objects::LabelResponse.new(post_request("label", body: payload))
    end
  end
end
