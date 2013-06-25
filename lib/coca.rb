require "coca/engine"
require 'coca/logger'
require 'coca/exceptions'
require 'coca/delegate'
require 'coca/cookie'
require 'devise/models/cocable'
require 'devise/strategies/cocable'

Devise.add_module :cocable,
                  :route => :session,
                  :strategy => true,
                  :controller => :sessions

module Coca
  mattr_accessor :masters, 
                 :servants, 
                 :cookie_domain, 
                 :check_source, 
                 :require_https, 
                 :propagate_updates, 
                 :token_ttl,
                 :secret,
                 :debug
  
  @@masters = []
  @@servants = []
  @@cookie_domain = :all
  @@check_source = true
  @@require_https = true
  @@propagate_updates = false
  @@token_ttl = 1800
  @@secret = "Unset"
  @@debug = true
  
  class << self
    def delegate_to(&block)
      @@masters.push Coca::Delegate.new(&block)
    end

    def delegate_from(&block)
      @@servants.push Coca::Delegate.new(&block)
    end
  
    def valid_servant?(referer, key)
      servants.find { |servant| servant.valid_referer?(referer) && valid_secret?(key) }
    end

    def valid_master?(referer, key)
      masters.find { |master| master.valid_referer?(referer) && valid_secret?(key) }
    end
  
    def valid_secret?(key)
      !!key && !key.blank? && key == Coca.secret
    end
  end
  
end

