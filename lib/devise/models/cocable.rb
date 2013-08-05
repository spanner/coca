require 'devise/strategies/cocable'

module Devise
  module Models
    module Cocable
      extend ActiveSupport::Concern

      # On successful authentication we return a json package. By default it will be the (signed) result of a normal call to ,
      # as_json, but since everything you return will be used to update a local model in the client application, you may not want to
      # return all the user columns. You can avoid that by defining an :as+json+_for_coca method in the model class. It should 
      # work exactly like the normal as_json method (so should take an options argument) but return only the values you want
      # to pass down to client applications.
      #
      # The returned values should almost certainly include `uid` and `authentication_token`. Everything else is up to you.
      #

      def as_json_for_coca(options={})
        as_json(options)
      end

      def to_json_with_signature(options={})
        if options[:purpose] == :coca
          Coca.signer.encode(as_json_for_coca(options))
        else
          to_json_without_signature(options)
        end
      end

      def self.included(base)
        base.class_eval {
          alias_method_chain :to_json, :signature
        }
      end

    end
  end
end
