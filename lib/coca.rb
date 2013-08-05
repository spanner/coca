require "coca/monkeys"
require "coca/engine"
require 'coca/delegate'
require 'coca/json'
require 'coca/auth_cookie'
require 'devise/models/cocable'
require 'devise/strategies/cocable'

Warden::Manager.after_set_user do |user, warden, options|
  Coca::AuthCookie.new(warden.cookies, options[:scope]).set(user)
end

Warden::Manager.before_logout do |user, warden, options|
  Coca::AuthCookie.new(warden.cookies, options[:scope]).unset
end

module Coca
  mattr_accessor :masters, 
                 :servants, 
                 :cookie_domain,
                 :check_source,
                 :require_https,
                 :propagate_updates,
                 :ttl,
                 :secret,
                 :debug,
                 :check_referers
  
  @@masters = []
  @@servants = []
  @@cookie_domain = :all
  @@check_source = true
  @@require_https = true
  @@propagate_updates = false
  @@ttl = 10.minutes
  @@secret = "Unset"
  @@debug = true
  @@check_referers = false
  
  class << self
    def add_master(name, &block)
      @@masters.push Coca::Delegate.new(name, &block)
    end

    def add_servant(name, &block)
      @@servants.push Coca::Delegate.new(name, &block)
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
    
    def check_referers?
      Rails.env.producation? && !!@@check_referers
    end
    
  end
end

Devise.add_module :cocable,
                  :route => :session,
                  :strategy => true,
                  :controller => :sessions
