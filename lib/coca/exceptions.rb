module Coca

  class CocaException < StandardError; end
  class DelegateNotFound < CocaException; end
  class ResponseNotUnderstood < CocaException; end

end
