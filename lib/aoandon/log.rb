# frozen_string_literal: true

module Aoandon
  class Log
    LOCAL_PATH = "log/aoandon.yml"
    GLOBAL_PATH = "/var/log/aoandon.yml"

    def initialize(verbose = false)
      file_path = if File.exist?(LOCAL_PATH)
                    LOCAL_PATH
                  else
                    GLOBAL_PATH
                  end

      @file = ::File.open(file_path, "a")
      @verbose = verbose

      puts "Log file: #{::File.expand_path(@file.path)}"
    end

    def message(*args)
      puts args.compact.map(&:to_s).join(" | ") if @verbose
      @file.puts "- #{args.compact.map(&:to_s)}"
      @file.flush
    end
  end
end
