#!/usr/bin/env ruby


use_bundle "system/monitoring"
use_bundle "hardware/network"

module Hardware
  module Network

    class ConnectionsByPort < Bixby::Monitoring::Base
      def monitor
        # count only those on specific ports
        port_hash = Hardware::Network.netstat_by_port(option(:port))
        port_hash.each_pair { |port, counter|
          add_metric({ :port => counter }, { :port => port })
        }
      end
    end

  end
end

Bixby::Monitoring::Base.subclasses.last.new.run if $0 == __FILE__
