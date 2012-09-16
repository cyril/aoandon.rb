module Aoandon
  class Syntax < Analysis
    def initialize(logger, options = {})
      super(logger, options)

      abort("Configuration file not found: #{options[:file]}") unless File.exist?(options[:file])
      @rules = Array(YAML::load_file(options[:file])['rules']).map {|rule| StaticRule.new(*rule) }

      puts "Ruleset:  #{File.expand_path(options[:file])}"
    end

    def test(packet)
      @rules.each do |rule|
        if match?(packet, rule.context)
          break if (@last_rule = rule).options['quick']
        end
      end

      if @last_rule && @last_rule.action != 'pass'
        message = @last_rule.options['msg'] || 'Bad packet detected!'
        dump = @last_rule.options['log'] ? packet : nil
        @logger.message(packet.time.iso8601, 'SYNTAX', @last_rule.action, message, dump)
      end
    end

    protected

    def match?(packet, network_context)
      network_context.update({'af' => af2id(packet.ip_ver)}) unless network_context.has_key?('af')
      match_proto?(packet, network_context) if packet.ip_ver == af(network_context.fetch('af'))
    end

    def af2id(af)
      if af == 4
        'inet'
      elsif af == 6
        'inet6'
      end
    end

    def af(name)
      if name.to_sym == :inet
        4
      elsif name.to_sym == :inet6
        6
      end
    end

    def match_proto?(packet, network_context)
      if network_context['proto']
        if packet.ip_proto == proto(network_context['proto'])
          if packet.ip_proto == 1
            match_proto_icmp?(packet, network_context)
          elsif packet.ip_proto == 6
            match_proto_tcp?(packet, network_context)
          elsif packet.ip_proto == 17
            match_proto_udp?(packet, network_context)
          elsif packet.ip_proto == 58
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
      if name.to_sym == :icmp
        1
      elsif name.to_sym == :icmp6
        58
      elsif name.to_sym == :tcp
        6
      elsif name.to_sym == :udp
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

      [['from', 'src'], ['to', 'dst']].each do |way, obj|
        unless network_context[way].fetch('addr') == 'any'
          result = result && refer2addr?((packet.send(obj)), network_context[way].fetch('addr'))
        end
      end

      result
    end

    def match_port?(packet, network_context)
      result = true

      [['from', 'sport'], ['to', 'dport']].each do |way, obj|
        if network_context[way].has_key?('port')
          result = result && refer2port?((packet.send(obj)).to_i, network_context[way].fetch('port'))
        end
      end

      result
    end

    def match_flag?(packet, network_context)
      return true unless network_context['flags']

      network_context['flags'].each do |flag|
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
      if pattern.is_a? Array
        pattern.include?(addr.to_num_s) || pattern.include?(addr.hostname)
      elsif pattern.is_a? Hash
        pattern.has_key?(addr.to_num_s) || pattern.has_key?(addr.hostname)
      elsif pattern.is_a? String
        addr.to_num_s == pattern        || addr.hostname == pattern
      else
        false
      end
    end

    def refer2port?(number, pattern)
      if pattern.is_a? Array
        pattern.include?(number)
      elsif pattern.is_a? Hash
        pattern.has_key?(number)
      elsif pattern.is_a? Fixnum
        number == pattern
      else
        false
      end
    end
  end
end
