module Aoandon
  class Analysis
    def initialize(logger, options = {})
      @logger = logger
    end

    def update(packet = '')
      raise NotImplementedError, 'Must subclass me'
    end
  end
end
