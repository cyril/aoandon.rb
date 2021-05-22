# frozen_string_literal: false

require "ipaddr"
require "optparse"
require "pcap"
require "time"
require "yaml"

require_relative "aoandon/analysis"
require_relative "aoandon/analysis/semantic"
require_relative "aoandon/analysis/syntax"
require_relative "aoandon/log"
require_relative "aoandon/static_rule"

Dir["lib/aoandon/dynamic_rule/*.rb"].each do |src|
  load src
end

module Aoandon
  class Nids
    CONF_PATH = "config/rules.yml"

    def initialize
      options = self.class.parse
      options[:file] = CONF_PATH unless options[:file]
      options[:interface] = Pcap.lookupdev unless options[:interface]
      puts "Starting Aoandon NIDS on interface #{options[:interface]}..."
      log = Log.new(options[:verbose])
      @syntax = Syntax.new(log, { file: options[:file] })
      @semantic = Semantic.new(log)
      @network_interface = Pcap::Capture.open_live(options[:interface])
    end

    def run
      puts "You can stop Aoandon NIDS by pressing Ctrl-C."

      @network_interface.each_packet do |packet|
        if packet.ip?
          @semantic.test(packet)
          @syntax.test(packet)
        end
      end

      @network_interface.close
    end

    def self.parse
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"
        opts.on("-f", "--file <path>", "Load the rules contained in file <path>.") { |f| options[:file] = f }
        opts.on("-h", "--help", "Help.") { puts opts; exit }
        opts.on("-i", "--interface <if>", "Sniff on network interface <if>.") { |i| options[:interface] = i }
        opts.on("-v", "--verbose", "Produce more verbose output.") { options[:verbose] = true }
        opts.on("-V", "--version", "Show the version number and exit.") { version; exit }
      end.parse!

      options
    end

    def self.version
      puts "Aoandon #{VERSION}"
    end

    trap("INT") { exit }
    at_exit { print "Stopping Aoandon NIDS... " }
    ObjectSpace.define_finalizer("string", proc { puts "done." })
  end
end
