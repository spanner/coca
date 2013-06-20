require 'devise/strategies/authenticatable'

module Devise
  module Strategies


    class Cocable < Authenticatable
      # Authenticate a user based on login and password params, returning to warden
      # success and the authenticated user if everything is okay. Otherwise defer to coca master.

      def authenticate!
        resource = valid_password? && mapping.to.authenticate_with_ldap(params[scope])
        return fail(:invalid) if resource.nil?

        if validate(resource)
          success!(resource)
        else
          fail(:invalid)
        end
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
