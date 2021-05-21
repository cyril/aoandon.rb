# frozen_string_literal: true

module Aoandon
  class Analysis
    def initialize(logger, _options = {})
      @logger = logger
    end

    def update(_packet = "")
      raise NotImplementedError, "Must subclass me"
    end
  end
end
