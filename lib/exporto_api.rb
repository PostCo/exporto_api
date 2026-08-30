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

  module Objects
    autoload :TokenResponse, "exporto_api/objects/token_response"
  end
end
