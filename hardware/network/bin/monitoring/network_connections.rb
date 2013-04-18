#!/usr/bin/env ruby

# Copyright (c) 2008-2013 Scout Monitoring
# Licensed under the MIT license
# See: https://github.com/scoutapp/scout-plugins

use_bundle "system/monitoring"

class NetworkConnections < Scout::Plugin

  OPTIONS=<<-EOS
    port:
      label: Ports
      notes: comma-delimited list of ports to monitor. Or specify all for summary info across all ports.
      default: "80,443,25"
  EOS

  def build_report
    report_hash={}
    port_hash = {}
    if option(:port).strip != "all"
      option(:port).split(/[, ]+/).each { |port| port_hash[port.to_i] = 0 }
    end

    lines = shell("netstat -n").split("\n")
    connections_hash = {:tcp => 0,
                        :udp => 0,
                        :unix => 0,
                        :total => 0}

    lines.each { |line|
      line = line.squeeze(" ").split(" ")
      next unless line[0] =~ /tcp|udp|unix/
      connections_hash[:total] += 1
      protocol = line[0].sub(/\d+/,'').to_sym
      connections_hash[protocol] += 1 if connections_hash[protocol]

      local_address = line[3].sub("::ffff:","") # indicates ip6 - remove so regex works
      port = local_address.split(":")[1].to_i
      port_hash[port] += 1 if port_hash.has_key?(port)
    }

    connections_hash.each_pair { |conn_type, counter|
      report_hash[conn_type]=counter
    }

    port_hash.each_pair { |port, counter|
      report_hash["Port #{port}"] = counter
    }

    report(report_hash)
  end

  # Use this instead of backticks. It's a separate method so it can be stubbed for tests
  def shell(cmd)
    `#{cmd}`
  end
end

Scout::Plugin.subclasses.first.new.run if $0 == __FILE__
