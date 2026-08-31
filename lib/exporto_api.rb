# frozen_string_literal: true

require_relative "exporto_api/version"

module ExportoAPI
  autoload :AuthClient, "exporto_api/auth_client"
  autoload :Client, "exporto_api/client"
  autoload :Base, "exporto_api/object"
  autoload :Resource, "exporto_api/resource"
  autoload :Error, "exporto_api/errors"
  autoload :APIError, "exporto_api/errors"
  autoload :AuthenticationError, "exporto_api/errors"
  autoload :ValidationError, "exporto_api/errors"
  autoload :NotFoundError, "exporto_api/errors"
  autoload :RateLimitError, "exporto_api/errors"
  autoload :ServerError, "exporto_api/errors"
  autoload :AuthResource, "exporto_api/resources/auth_resource"
  autoload :LabelResource, "exporto_api/resources/label_resource"
  autoload :LabelMethodResource, "exporto_api/resources/label_method_resource"
  autoload :OrderResource, "exporto_api/resources/order_resource"
  autoload :ShipmentResource, "exporto_api/resources/shipment_resource"

  module Objects
    autoload :LabelResponse, "exporto_api/objects/label_response"
    autoload :LabelMethodResponse, "exporto_api/objects/label_method_response"
    autoload :ShipmentResponse, "exporto_api/objects/shipment_response"
    autoload :TokenResponse, "exporto_api/objects/token_response"
  end
end
