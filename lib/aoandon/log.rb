module Aoandon
  class Log
    def initialize(verbose = false)
      @file = if File.exist?('log/aoandon.yml')
        File.open('log/aoandon.yml', 'a')
      else
        File.open('/var/log/aoandon.yml', 'a')
      end

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
