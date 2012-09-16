module Aoandon
  class Semantic < Analysis
    def initialize(logger, options = {})
      super(logger, options)

      puts "Modules:  #{DynamicRule.constants.join(', ')}"
    end

    def test(packet)
      if defined? DynamicRule
        DynamicRule.constants.each do |rule|
          if DynamicRule.const_get(rule).control?(packet)
            dump = DynamicRule.const_get(rule).logging?(packet) ? packet : nil
            message = if DynamicRule.const_get(rule).constants.include?(:MESSAGE)
              DynamicRule.const_get(rule)::MESSAGE
            else
              nil
            end

            @logger.message(packet.time.iso8601, 'SEMANT', rule.downcase, message, dump)
          end
        end
      end
    end
  end
end
