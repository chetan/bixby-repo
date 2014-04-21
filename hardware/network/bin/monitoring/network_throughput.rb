#!/usr/bin/env ruby

# Originally based on scout-plugins/network_throughput
# Copyright (c) 2008-2013 Scout Monitoring
# Licensed under the MIT license
# See: https://github.com/scoutapp/scout-plugins

use_bundle "system/monitoring"
use_bundle "hardware/network"

module Hardware
  module Network

    class Throughput < Scout::Plugin
      def build_report

        interfaces = memoize(:interfaces) {
          Hardware::Network.list_interfaces(option(:interfaces))
        }

        if interfaces.empty? then
          all_interfaces = Hardware::Network.list_interfaces(/.*/)
          error(
            "No interfaces were found that matched the regular expression [#{option(:interfaces)}]." +
            " You can modify the regular expression in the plugin's advanced settings.\n\n" +
            "Possible interfaces:\n" + all_interfaces.join("\n")
            )
        end

        ret = throughput(interfaces)
        ret.each do |interface, metrics|
          add_metric metrics, {:interface => interface}
        end
      end



      private


      def throughput(interfaces)
        if linux? then
          throughput_linux(interfaces)
        elsif darwin? then
          throughput_darwin(interfaces)
        end
      end



      def throughput_linux(interfaces)

        ret = {}

        %x(cat /proc/net/dev).split("\n")[2..-1].each do |line|
          iface, rest = line.split(':', 2).collect { |e| e.strip }
          next unless interfaces.include? iface

          # pull out the stats we want
          in_bytes, in_packets, out_bytes, out_packets = rest.split(/\s+/).values_at(0, 1, 8, 9).map { |i| i.to_i }

          add_stats(ret, iface, in_packets, in_bytes, out_packets, out_bytes)
        end

        return ret
      rescue Exception => e
        error("#{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
      end

      def throughput_darwin(interfaces)
        ret = {}

        interfaces.each do |iface|

          # just ignore interfaces like this for now:
          # en3*  1500  <Link#5>    32:00:16:0f:17:c0        0     0          0        0     0          0     0
          next if iface =~ /\*$/

          # Name   Mtu     Network     Address              Ipkts     Ierrs Ibytes        Opkts     Oerrs Obytes       Coll
          # "en0", "1500", "<Link#4>", "00:1f:5b:3d:6b:08", "7235347", "0", "6759061727", "4887571", "0", "712511194", "0"
          stats = systemu("netstat -biI #{iface}").stdout.split(/\n/).reject{ |s| s =~ /^Name/ }.first.
            squeeze(" ").split(/ /)

          # pull out stats we want
          in_packets, in_bytes, out_packets, out_bytes = stats.values_at(4, 6, 7, 9).map { |i| i.to_i }

          add_stats(ret, iface, in_packets, in_bytes, out_packets, out_bytes)
        end

        return ret
      end

      def add_stats(ret, iface, in_packets, in_bytes, out_packets, out_bytes)
        # do stat calculations
        r = {}
        r.merge! local_counter(iface, "rx.bytes",    in_bytes,    :per => :second, :round => 0)
        r.merge! local_counter(iface, "rx.packets",  in_packets,  :per => :second, :round => 0)
        r.merge! local_counter(iface, "tx.bytes",    out_bytes,   :per => :second, :round => 0)
        r.merge! local_counter(iface, "tx.packets",  out_packets, :per => :second, :round => 0)
        ret[iface] = r
      end

      # Use memory to compute metric based on two intervals
      def local_counter(iface, name, value, options = {})

        ret = nil
        @current_time ||= Time.now

        key = "#{iface}.#{name}"
        if data = memory(key) then

          last_time, last_value = data[:time], data[:value]
          elapsed_seconds       = @current_time - last_time

          # We won't log it if the value has wrapped or enough time hasn't
          # elapsed
          if value >= last_value && elapsed_seconds >= 1
            result = value - last_value

            case options[:per]
            when :second, 'second'
              result = result / elapsed_seconds.to_f
            when :minute, 'minute'
              result = result / elapsed_seconds.to_f / 60.0
            end

            if r = options[:round] then
              if r == 0 then
                result = result.to_i
              elsif r > 0 then
                result = (result * (10 ** options[:round])).round / (10 ** options[:round]).to_f
              end
            end

            ret = { name => result }
          end

        end

        remember(key => { :time => @current_time, :value => value })
        return ret || {}
      end

    end

  end
end

Scout::Plugin.subclasses.first.new.run if $0 == __FILE__
