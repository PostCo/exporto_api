# frozen_string_literal: true

module ExportoAPI
  class AuthResource < Resource
    def token(scope: nil)
      body = {"grant_type" => "client_credentials"}
      body["scope"] = scope unless scope.nil?

      Objects::TokenResponse.new(post_request("auth/token", body: body))
    end
  end
end
