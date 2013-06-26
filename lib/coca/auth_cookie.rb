require 'signed_json'

# Based on the same class in devise-login-cookie by pda
# https://github.com/pda/devise-login-cookie

module Coca

  class AuthCookie

    def initialize(cookies, scope)
      @cookies = cookies
      @scope = scope
    end

    # Sets the cookie, referencing the given resource.id (e.g. User)
    def set(resource)
      @cookies[cookie_name] = cookie_options.merge(:value => encoded_value(resource))
    end

    # Unsets the cookie via the HTTP response.
    def unset
      @cookies.delete cookie_name, cookie_options
    end
    
    def token
      value[0]
    end

    # The Time at which the cookie was created.
    def created_at
      valid? ? Time.at(value[1]) : nil
    end

    # Whether the cookie appears valid.
    def valid?
      present? && value.all?
    end

    def present?
      @cookies[cookie_name].present?
    end

    # Whether the cookie was set since the given Time
    def set_since?(time)
      created_at && created_at >= time
    end

  private

    def value
      begin
        @value = signer.decode @cookies[cookie_name]
      rescue SignedJson::Error
        [nil, nil]
      end
    end

    def cookie_name
      :"coca_#{@scope}_token"
    end

    def encoded_value(resource)
      signer.encode [ resource.authentication_token, Time.now.to_i ]
    end

    def cookie_options
      @session_options ||= Rails.configuration.session_options
      @session_options.slice(:path, :secure, :httponly).merge(:domain => Coca.cookie_domain)
    end

    def signer
      @signer ||= SignedJson::Signer.new(Coca.secret)
    end

  end

end