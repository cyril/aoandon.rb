# frozen_string_literal: true

module Aoandon
  class Syntax < Analysis
    def initialize(logger, options = {})
      super(logger, options)

      abort("Configuration file not found: #{options[:file]}") unless File.exist?(options[:file])
      @rules = Array(YAML.load_file(options[:file])["rules"]).map { |rule| StaticRule.new(*rule) }

      puts "Ruleset:  #{File.expand_path(options[:file])}"
    end

    def test(packet)
      @rules.each do |rule|
        break if match?(packet, rule.context) && (@last_rule = rule).options["quick"]
      end

      if @last_rule && @last_rule.action != "pass"
        message = @last_rule.options["msg"] || "Bad packet detected!"
        dump = @last_rule.options["log"] ? packet : nil
        @logger.message(packet.time.iso8601, "SYNTAX", @last_rule.action, message, dump)
      end
    end

    protected

    def match?(packet, network_context)
      network_context.update({ "af" => af2id(packet.ip_ver) }) unless network_context.key?("af")
      match_proto?(packet, network_context) if packet.ip_ver == af(network_context.fetch("af"))
    end

    def af2id(af)
      case af
      when 4
        "inet"
      when 6
        "inet6"
      end
    end

    def af(name)
      case name.to_sym
      when :inet
        4
      when :inet6
        6
      end
    end

    def match_proto?(packet, network_context)
      if network_context["proto"]
        if packet.ip_proto == proto(network_context["proto"])
          case packet.ip_proto
          when 1
            match_proto_icmp?(packet, network_context)
          when 6
            match_proto_tcp?(packet, network_context)
          when 17
            match_proto_udp?(packet, network_context)
          when 58
            match_proto_icmp6?(packet, network_context)
          else
            match_addr?(packet, network_context)
          end
        end
      else
        match_addr?(packet, network_context)
      end
    end

    def proto(name)
      case name.to_sym
      when :icmp
        1
      when :icmp6
        58
      when :tcp
        6
      when :udp
        17
      end
    end

    def match_proto_icmp?(packet, network_context)
      match_addr?(packet, network_context)
    end

    def match_proto_icmp6?(packet, network_context)
      match_proto_icmp?(packet, network_context)
    end

    def match_addr?(packet, network_context)
      result = true

      [%w[from src], %w[to dst]].each do |way, obj|
        unless network_context[way].fetch("addr") == "any"
          result &&= refer2addr?(packet.send(obj), network_context[way].fetch("addr"))
        end
      end

      result
    end

    def match_port?(packet, network_context)
      result = true

      [%w[from sport], %w[to dport]].each do |way, obj|
        if network_context[way].key?("port")
          result &&= refer2port?(packet.send(obj).to_i, network_context[way].fetch("port"))
        end
      end

      result
    end

    def match_flag?(packet, network_context)
      return true unless network_context["flags"]

      network_context["flags"].each do |flag|
        return true if packet.send("tcp_#{flag}?")
      end

      false
    end

    def match_proto_tcp?(packet, network_context)
      match_proto_udp?(packet, network_context) && match_flag?(packet, network_context)
    end

    def match_proto_udp?(packet, network_context)
      match_addr?(packet, network_context) && match_port?(packet, network_context)
    end

    def refer2addr?(addr, pattern)
      case pattern
      when Array
        pattern.include?(addr.to_num_s) || pattern.include?(addr.hostname)
      when Hash
        pattern.key?(addr.to_num_s) || pattern.key?(addr.hostname)
      when String
        addr.to_num_s == pattern || addr.hostname == pattern
      else
        false
      end
    end

    def refer2port?(number, pattern)
      case pattern
      when Array
        pattern.include?(number)
      when Hash
        pattern.key?(number)
      when Integer
        number == pattern
      else
        false
      end
    end
  end
end
