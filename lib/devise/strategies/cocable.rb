require 'devise/strategies/authenticatable'

module Devise
  module Strategies

    class Cocable < Authenticatable
      def valid?
        valid_for_params_auth? || cookie.valid?
      end

      def authenticate!
        resource = mapping.to.where(:uid => cookie.uid, :authentication_token => cookie.auth_token).first || delegate!
        success!(resource) if validate(resource)
      end
      
      def delegate!
        response = nil
        credentials = authentication_hash.merge(:auth_token => cookie.value)
        Coca.masters.each do |master|
          response = master.authenticate(credentials)
          break if response
        end
        resource = mapping.to.where(:uid => response.uid).first_or_create(response.except(:uid)) if response
      end

    private

      def cookie
        @cookie ||= Cookie.new(cookies, scope)
      end

    end
  end
end

Warden::Strategies.add(:cocable, Devise::Strategies::Cocable)
