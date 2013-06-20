# encoding: utf-8
require 'devise'
require 'devise/strategies/cocable'
require 'devise/models/cocable'

module Devise
  # Allow logging
  mattr_accessor :coca_logger
  @@coca_logger = true
end

Devise.add_module(:cocable,
                  :route => :session,
                  :strategy   => true,
                  :controller => :sessions,
                  :model  => 'devise/models/cocable')
