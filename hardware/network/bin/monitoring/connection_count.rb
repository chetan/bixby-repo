#!/usr/bin/env ruby


use_bundle "system/monitoring"
use_bundle "hardware/network"

module Hardware
  module Network

    class Connections < Bixby::Monitoring::Base
      def monitor
        add_metric(Hardware::Network.netstat())
      end
    end

  end
end

Bixby::Monitoring::Base.subclasses.last.new.run if $0 == __FILE__
