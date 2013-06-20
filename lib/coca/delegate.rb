require 'resolv'

module Coca
  class Delegate
    attr_writer :host, :port, :secret, :ttl
    
    def initialise
      yield self if block_given?
    end

    def ttl
      @ttl ||= Coca.token_ttl
    end
    
    def host
      @host ||= "localhost"
    end
    
    def port
      @port ||= 80
    end
    
    def ip_address
      @ip ||= Resolv.new.getaddress(host)
    end
    
    def valid_secret?(key)
      !!key && !key.blank? && key == secret
    end
    
    def valid_referer?(referer)
      !!referer && !referer.blank? && referer == ip_address
    end
    
  end
end