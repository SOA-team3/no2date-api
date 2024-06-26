# frozen_string_literal: true

module No2Date
  # Methods for controllers to mixin
  module SecureRequestHelpers
    class UnauthorizedRequestError < StandardError; end
    class NotFoundError < StandardError; end

    def secure_request?(routing)
      routing.scheme.casecmp(Api.config.SECURE_SCHEME).zero?
    end

    def authorization(headers)
      return nil unless headers['AUTHORIZATION']

      scheme, auth_token = headers['AUTHORIZATION'].split
      return nil unless scheme.match?(/^Bearer$/i)

      scoped_auth(auth_token)
    end

    def scoped_auth(auth_token)
      token = AuthToken.new(auth_token)
      account_data = token.payload['attributes']
      # puts "helpers.rb Account data: #{account_data}"

      { account: Account.first(username: account_data['username']),
        scope: AuthScope.new(token.scope) }
    end
  end
end
