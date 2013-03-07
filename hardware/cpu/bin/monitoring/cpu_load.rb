#!/usr/bin/env ruby

use_bundle "hardware/cpu"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module CPU

    class LoadAverage < Bixby::Monitoring::Base

      def get_options
        return {}
      end

      def monitor
        num_processors = memoize(:processors) { Hardware::CPU.num_processors() }

        load = Hardware::CPU.get_load(num_processors)
        if load.nil? then
          error("failed to retrieve uptime")
          return
        end
        add_metric(load)
      end

    end
  end
end # Monitoring
end # Bixby

Bixby::Monitoring::CPU::LoadAverage.new.run if $0 == __FILE__
