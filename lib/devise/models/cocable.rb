require 'devise/strategies/cocable'

module Devise
  module Models
    module Cocable
      extend ActiveSupport::Concern

      def active_for_authentication?
        true
      end

      def inactive_message
        :inactive
      end

    end
  end
end
