module Coca

  class Logger    
    def self.send(message, logger=Rails.logger)
      if ::Devise.coca_logger
        logger.add 0, "  \e[36mCoca:\e[0m #{message}"
      end
    end
  end

end
