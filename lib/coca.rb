require "coca/engine"
require "coca/link"
require "devise/cocable"

module Coca
  mattr_accessor :masters, 
                 :servants, 
                 :cookie_domain, 
                 :check_source, 
                 :require_https, 
                 :propagate_updates, 
                 :token_ttl
  
  @@masters = []
  @@servants = []
  @@cookie_domain = ""
  @@check_source = true
  @@require_https = true
  @@propagate_updates = false
  @@token_ttl = 1800
  
  def look_up
    @@masters.push Coca::Delegate.new &block
  end

  def look_down
    @@servants.push Coca::Delegate.new &block
  end
  
  def valid_servant?(referer, key)
    servants.find { |servant| servant.valid_referer?(referer) && servant.valid_secret?(key) }
  end

  def valid_master?(referer, key)
    masters.find { |master| master.valid_referer?(referer) && master.valid_secret?(key) }
  end
  
end
