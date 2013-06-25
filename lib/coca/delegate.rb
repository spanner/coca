require 'resolv'
require 'httparty'

module Coca
  class Delegate
    include HTTParty
    attr_writer :host, :port, :ttl, :protocol
    
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
      @port
    end
    
    def protocol
      @protocol ||= 'https'
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
    
    def valid_referer?(referer)
      !!referer && !referer.blank? && referer == ip_address
    end
    
    def host_url_with_port
      hup = "#{protocol}://#{host}"
      hup << ":#{port}" if port
      hup
    end
    
    def url
      URI.join(host_url_with_port, path).to_s
    end
        
    def authenticate(credentials)
      response = HTTParty.get url, :user => credentials
      response.body if response.code != 401
    end
    
  end
end