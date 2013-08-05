require 'resolv'
require 'httparty'

module Coca
  class Delegate
    include HTTParty
    attr_writer :name, :host, :port, :ttl, :protocol
    
    def initialize(name='')
      @name = name
      yield self if block_given?
    end
    
    def name
      @name
    end
    
    def ttl
      @ttl ||= Coca.ttl
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
      @path ||= "/coca/check.json"
    end
    
    def ip_address
      @ip ||= Resolv.new.getaddress(host)
    end
    
    def valid_referer?(referer)
      if Coca.check_referers?
        !!referer && !referer.blank? && referer == ip_address
      else
        true
      end
    end
    
    def host_url_with_port
      hup = "#{protocol}://#{host}"
      hup << ":#{port}" if port
      hup
    end
    
    def url
      @url ||= URI.join(host_url_with_port, path).to_s
    end
        
    def authenticate(scope, credentials)
      response = HTTParty.post url, :body => {:scope => scope, :"#{scope}" => credentials}
      response.body if response.code == 200
    end
    
  end
end