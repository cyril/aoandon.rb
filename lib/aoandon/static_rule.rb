module Aoandon
  class StaticRule < Struct.new(:action, :context, :options)
    def initialize(*args)
      super(*args)

      self.context['from'] ||= {'addr' => 'any'}
      self.context['to'  ] ||= {'addr' => 'any'}

      self.context['from'].update('addr' => 'any') unless self.context['from']['addr']
      self.context['to'  ].update('addr' => 'any') unless self.context['to'  ]['addr']

      self.options ||= {}
      self.options.update('log' => false) unless self.options.has_key?('log')
    end
  end
end
