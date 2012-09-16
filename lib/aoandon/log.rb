module Aoandon
  class Log
    def initialize(verbose = false)
      @file = File.open('log/aoandon.yml', 'a')
      @verbose = verbose

      puts "Log file: #{File.expand_path(@file.path)}"
    end

    def message(*args)
      puts args.compact.map(&:to_s).join(' | ') if @verbose
      @file.puts "- #{args.compact.map(&:to_s)}"
      @file.flush
    end
  end
end
