# frozen_string_literal: true

module Aoandon
  StaticRule = Struct.new(:action, :context, :options) do
    def initialize(*args)
      super(*args)

      context["from"] ||= { "addr" => "any" }
      context["to"] ||= { "addr" => "any" }

      context["from"].update("addr" => "any") unless context["from"]["addr"]
      context["to"].update("addr" => "any") unless context["to"]["addr"]

      self.options ||= {}
      self.options.update("log" => false) unless self.options.key?("log")
    end
  end
end
