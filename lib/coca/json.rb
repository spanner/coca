module Coca
  class Json
    # On successful authentication we return a json package. By default it will be the result of a normal call to as_json,
    # but since everything you return will be used to update a local model in the client application, you may not want to
    # return all the user columns. You can avoid that by defining an :as+json+_for_coca method in the model class. It should 
    # work exactly like the normal as_json method (so should take an options argument) but return only the values you want
    # to pass down to client applications.
    #
    # Those values should almost certainly include `uid` and `authentication_token`. Everything else is up to you.
    #
    def as_json_with_format(options={})
      if options[:format] == :coca 
        as_json_for_coca(options)
      else
        as_json_without_format(options)
      end
    end
    
    def as_json_for_coca(options={})
      as_json_without_format(options)
    end

    def self.included(base)
      base.class_eval {
        alias_method_chain :as_json, :format
      }
    end

  end
end

ActiveRecord::Base.send :include, Coca::Json
