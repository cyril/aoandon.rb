# Aoandon

<span lang="ja"><ruby>青<rt>ao</rt>行燈<rt>andon</rt></ruby></span> is a minimalist network intrusion detection system (NIDS).

![Blue andon creature](https://raw.githubusercontent.com/cyril/aoandon.rb/main/blue-andon-creature.jpg)

## Status

[![Gem Version](https://badge.fury.io/rb/aoandon.svg)](https://badge.fury.io/rb/aoandon)
[![Build Status](https://travis-ci.org/cyril/aoandon.rb.svg?branch=main)](https://travis-ci.org/cyril/aoandon.rb)
[![Inline Docs](https://inch-ci.org/github/cyril/aoandon.rb.svg)](https://inch-ci.org/github/cyril/aoandon.rb)
![](https://ruby-gem-downloads-badge.herokuapp.com/aoandon?type=total)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "aoandon"
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install accept_language
```

## Getting started

To start, let's look at the machine's network interfaces in console:

```sh
ifconfig
```

And let's display the help menu:

```sh
aoandon -h
```

    Usage: aoandon [options]
        -f, --file <path>                Load the rules contained in file <path>.
        -h, --help                       Help.
        -i, --interface <if>             Sniff on network interface <if>.
        -v, --verbose                    Produce more verbose output.
        -V, --version                    Show the version number and exit.
    Stopping Aoandon NIDS... done.

Now, let's start scanning the network traffic on the machine's en0 network interface:

```sh
sudo aoandon -i en0 -v
```

    Starting Aoandon NIDS on interface en0...
    Log file: /var/log/aoandon.yml
    Ruleset:  /Users/bob/code/aoandon.rb/config/rules.yml
    Modules:  Less1024
    You can stop Aoandon NIDS by pressing Ctrl-C.
    2014-05-30T11:46:44+02:00 | SYNTAX | info | Suspected packet! | 42.0.0.1:8080 > 192.168.1.88:64563 .AP...
    2014-05-30T11:46:44+02:00 | SYNTAX | info | Suspected packet! | 192.168.1.88:64563 > 42.0.0.1:8080 .A....

## Usage

Aoandon NIDS is the selective ignoring or alerting of data packets as they pass through its network interface.  The criteria that it uses when inspecting packets are based on the Layer 3 (IPv4 and IPv6) and Layer 4 (TCP, UDP) headers.  The most often used criteria are source and destination address, source and destination port, and protocol.

Rules specify the criteria that a packet must match and the resulting action, either pass or alert, that is taken when a match is found.  Rules are evaluated in sequential order, first to last.  Unless the packet matches a rule containing the `quick` keyword, the packet will be evaluated against all rules before the final action is taken.  The last rule to match is the *winner* and will dictate what action to take on the packet.  There is an implicit pass all at the beginning of a ruleset meaning that if a packet does not match any rule the resulting action will be pass.

Both static and dynamic ruleset can be applied to packets.

### Static ruleset

Aoandon NIDS reads its configuration rules from `config/rules.yml` at boot time.  In order to be able to load rules, this JSON/YAML file must have at least a `rules` key.

#### Rule syntax

The general syntax for static rules is:

1. action
2. context
3. options

Where *action* can use as a logger level such as INFO or ERROR that indicate alerts' importance.  Note: the `pass` action will ignore the packet back to the kernel for further processing while any other action will react.

Every *context* params are evaluated for analysis to determine whether a given package matches.

The last part, *options*, can be:

* `log`: specifies that the packet should be logged.
* `quick`: if a packet matches a rule specifying `quick`, then that rule is considered the last matching rule and the specified action is taken.
* `msg`: tells the alerting engine the message to print to an alert.

#### Default alert

The recommended practice when setting up a NIDS is to take a "default alert" approach.  That is, to alert everything and then selectively allow certain traffic through the interface.  This approach is recommended because it errs on the side of caution and also makes writing a ruleset easier.

To create a default alert sniffer policy, the first rules should be:

```yaml
[ info, {}, {log: true, msg: "Suspected packet!"} ]
```

This will alert all traffic on the given interface in either direction from anywhere to anywhere.

#### The `quick` keyword

As indicated earlier, each packet is evaluated against the sniffer ruleset from top to bottom.  By default, the packet is marked for passage, which can be changed by any rule, and could be changed back and forth several times before the end of the sniffer rules.  The last matching rule *wins*.  There is an exception to this: the `quick` option on a sniffing rule has the effect of canceling any further rule processing and causes the specified action to be taken.  Let's look at a couple examples:

Wrong:

```yaml
- [ crit, {proto: tcp, to: {port: 22}}, {msg: "...SSH?", log: true} ]
- [ pass, {} ]
```

In this case, the alert line may be evaluated, but will never have any effect, as it is then followed by a line which will ignore everything.

Better:

```yaml
- [ crit, {proto: tcp, to: {port: 22}}, {msg: "...SSH?", log: true, quick: true} ]
- [ pass, {} ]
```

These rules are evaluated a little differently.  If the alert line is matched, due to the `quick` option, the packet will be reported, and the rest of the ruleset will be ignored.

#### Ruleset example

```yaml
hosts:
  - &honeypots [ 192.168.1.4, 192.168.1.9 ]
  - &my_station 192.168.1.38

rules:
  # "default alert" approach
  - [ info, {}, {log: true, msg: "Suspected packet!"} ]

  # then, selectively ignore certain traffic
  - [ warn, {to: {addr: *honeypots}}, {msg: "Touché.", quick: true, log: true} ]
  - [ pass, {from: {addr: *my_station}} ]
  - [ pass, {to: {addr: *my_station}} ]
  - [ pass, {to: {addr: '224.0.0.1'}} ]
```

#### A more complete ruleset example

```yaml
macros:
  web_server: &web_server
    114.21.70.71
  gateway: &gw
    192.168.0.1

tables:
  redzone: &redzone
    - "81.15.142.23"
  hacker: &id001
    - 81.15.142.23
    - 42.154.25.213
  blacklist: &blacklist
    - *id001
    - *gw
    - 81.15.142.23
    - "64.81.240.57"
  unknown:
    - any
  mz: &mz
    192.168.0.201
  dmz: &dmz
    sql_server: &sql_server
      10.0.0.2

ports:
  web: &www
    - 80
    - 443
  p2p:
    - 63192

messages:
  - &msg001 "ICMP packet from Google to MZ"
  - &msg002 "MZ intrusion detected!"

rules:
  # "default alert" approach
  - [ info, {}, {quick: true, log: true, msg: "Suspected packet!"} ]

  # then, selectively ignore certain traffic
  - [ pass, {af: inet, from: {addr: any}, to: {addr: any}} ]
  - [ warn, {proto: tcp, from: {addr: *blacklist}, to: {addr: any, port: *www}, flags: syn} ]
  - [ warn, {proto: tcp, from: {addr: any, port: 123}, to: {addr: *dmz}} ]
  - [ crit, {af: inet6, from: {addr: any}, to: {addr: any}}, {log: true} ]
  - [ pass, {af: inet, proto: tcp, from: {addr: *mz}, to: {addr: *web_server, port: *www}, {quick: true}} ]
  - [ warn, {proto: udp, from: {addr: *redzone}, to: {addr: 10.1.0.32, port: 21}} ]
  - [ info, {proto: tcp, from: {addr: 172.16.0.6}, to: {addr: 192.168.0.14, port: 22}} ]
  - [ crit, {proto: tcp, from: {addr: *blacklist}, to: {addr: *mz}}, {log: true, msg: *msg002} ]
  - [ info, {proto: tcp, to: {addr: 192.168.0.14, port: 22}} ]
  - [ pass, {proto: tcp, from: {addr: *id001}, to: {addr: *sql_server, port: 3306}} ]
  - [ info, {af: inet, proto: icmp, from: {addr: google.com}, to: {addr: *mz}}, {log: true, msg: *msg001} ]
```

### Dynamic ruleset

Some semantic analysis can also be done through Aoandon NIDS extensions, using modules such as:

```ruby
# lib/aoandon/dynamic_rule/less1024.rb
module Aoandon
  module DynamicRule
    module Less1024
      MESSAGE = "Port numbers < 1024"
      PROTO_TCP = 6
      PROTO_UDP = 17
      WELL_KNOWN_PORTS = (0..1023)

      def self.control?(packet)
        (tcp?(packet) || (udp?(packet) && different_ports?(packet.sport, packet.dport))) &&
          less_1024?(packet.sport) && less_1024?(packet.dport)
      end

      def self.logging?(packet)
        false
      end

      private

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
```

```ruby
# lib/aoandon/dynamic_rule/more_fragments.rb
module Aoandon
  module DynamicRule
    module MoreFragments
      MESSAGE = "More Fragment bit is set"

      def self.control?(packet)
        packet.ip_mf?
      end

      def self.logging?(packet)
        false
      end
    end
  end
end
```

```ruby
# lib/aoandon/dynamic_rule/same_ip.rb
module Aoandon
  module DynamicRule
    module SameIp
      LOCALHOST = "127.0.0.1"
      MESSAGE = "Same IP"

      def self.control?(packet)
        packet.ip_src == packet.ip_dst && !loopback?(packet.ip_src)
      end

      def self.logging?(packet)
        false
      end

      private

      def self.loopback?(ip_addr)
        ip_addr.to_num_s == LOCALHOST
      end
    end
  end
end
```

```ruby
# lib/aoandon/dynamic_rule/syn_flood.rb
module Aoandon
  module DynamicRule
    module SynFlood
      BUFFER = 20
      MESSAGE = "SYN flood attack"
      PROTO_TCP = 6

      def self.control?(packet)
        tcp?(packet) && fifo!(packet.tcp_syn?) && packet.tcp_syn? && overflow?
      end

      def self.logging?(packet)
        false
      end

      private

      def self.fifo!(input)
        stack << input
        stack.shift
      end

      def self.overflow?
        stack == [true] * BUFFER
      end

      def self.stack
        @syn_flood_stack ||= [false] * BUFFER
      end

      def self.tcp?(packet)
        packet.ip_proto == PROTO_TCP
      end
    end
  end
end
```

## Versioning

__Aoandon__ uses [Semantic Versioning 2.0.0](https://semver.org/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
