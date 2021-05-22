# frozen_string_literal: true

module Aoandon
  module DynamicRule
    module Less1024
      MESSAGE = "Port numbers < 1024"
      PROTO_TCP = 6
      PROTO_UDP = 17
      WELL_KNOWN_PORTS = (0..1023).freeze

      def self.control?(packet)
        (tcp?(packet) || (udp?(packet) && different_ports?(packet.sport, packet.dport))) &&
          less_1024?(packet.sport) && less_1024?(packet.dport)
      end

      def self.logging?(_packet)
        true
      end

      def self.different_ports?(src_port, dst_port)
        src_port != dst_port
      end

      def self.less_1024?(port)
        WELL_KNOWN_PORTS.include?(port)
      end

      def self.tcp?(packet)
        packet.ip_proto == PROTO_TCP
      end

      def self.udp?(packet)
        packet.ip_proto == PROTO_UDP
      end
    end
  end
end
