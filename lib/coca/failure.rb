module Coca
  class Failure < Devise::FailureApp
    def respond
      head :unauthorized
    end
  end
end