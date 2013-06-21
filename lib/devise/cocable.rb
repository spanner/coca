# encoding: utf-8
require 'devise'
require 'devise/strategies/cocable'

Devise.add_module(:cocable,
                  :route => :session,
                  :strategy => true,
                  :controller => :sessions)
