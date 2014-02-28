
# Originally based on scout-plugins/network_connections
# Copyright (c) 2008-2013 Scout Monitoring
# Licensed under the MIT license
# See: https://github.com/scoutapp/scout-plugins

module Hardware
  module Network

    extend Bixby::PlatformUtil


    def self.netstat
      cmd = systemu("netstat -n")
      if cmd.fail? then
        # TODO
      end

      connections_hash = {:tcp => 0,
                          :udp => 0,
                          :unix => 0,
                          :total => 0}

      cmd.stdout.split("\n").each { |line|
        line = line.squeeze(" ").split(" ")
        next unless line[0] =~ /tcp|udp|unix/ || line[1] =~ /stream|dgram/

        connections_hash[:total] += 1
        if mac? and line[1] =~ /stream|dgram/ then
          protocol = :unix
        else
          protocol = line[0].sub(/\d+/,'').to_sym
        end
        connections_hash[protocol] += 1 if connections_hash[protocol]
      }

      return connections_hash
    end

    def self.netstat_by_port(port)

      port_hash = {}
      if port.nil? or port.empty? then
        return port_hash
      end

      # populate list of interested ports
      port.split(/[, ]+/).each { |port| port_hash[port.to_i] = 0 }

      cmd = systemu("netstat -n")
      if cmd.fail? then
        # TODO
      end

      cmd.stdout.split("\n").each { |line|
        line = line.squeeze(" ").split(" ")
        next unless line[0] =~ /tcp|udp|unix/ || line[1] =~ /stream|dgram/

        local_address = line[3].sub("::ffff:","") # indicates ip6 - remove so regex works
        if mac? then
          local_port = local_address.split(/\./)[-1].to_i
        else
          local_port = local_address.split(":")[1].to_i
        end
        port_hash[local_port] += 1 if port_hash.has_key?(local_port)
      }

      return port_hash
    end




    private



    def self.list_interfaces(interfaces)
      if darwin? then
        regex = Regexp.compile(interfaces || /en/)
        list_interfaces_darwin(regex)
      else
        regex = Regexp.compile(interfaces || /venet|eth/)
        list_interfaces_linux(regex)
      end
    end

    def self.list_interfaces_linux(regex)
      systemu("cat /proc/net/dev | grep : | awk '{print $1}'").stdout.split(/\n/).
        map{|s| s.split(/:/).first }.find_all{ |s| s =~ regex }.sort.uniq
    end

    def self.list_interfaces_darwin(regex)
      systemu("netstat -bi | awk '{print $1}'").stdout.split(/\n/).
        find_all{ |s| s =~ regex }.sort.uniq
    end

  end
end
