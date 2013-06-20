require 'devise/strategies/authenticatable'

module Devise
  module Strategies

    class Cocable < TokenAuthenticatable
      # Try to authenticate locally. If that fails, pass on request to coca master, if any.
      
      def valid?
        valid_for_params_auth? || valid_for_token_auth?
      end

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
