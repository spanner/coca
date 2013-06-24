require 'resolv'
require 'httparty'

module Coca
  class Delegate
    include HTTParty
    attr_writer :host, :port, :ttl, :client_class
    
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
    
    def base_uri
      [host, port].compact.join(':')
    end

    def path
      @path ||= "/coca/user"
    end
    
    def ip_address
      @ip ||= Resolv.new.getaddress(host)
    end
    
    def client_class
      @client_class ||= "Coca::Client"
    end
    
    def valid_referer?(referer)
      !!referer && !referer.blank? && referer == ip_address
    end
    
    def url
      URI.join(base_uri, path)
    end
        
    def authenticate!(credentials)
      response = HTTParty.get url, :user => credentials
      response.body if response.code != 401
    end
    
  end
end