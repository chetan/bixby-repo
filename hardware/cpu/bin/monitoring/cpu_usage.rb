#!/usr/bin/env ruby

use_bundle "hardware/cpu"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module CPU

    class Usage < Bixby::Monitoring::Base

      def get_options
        return {}
      end

      def monitor
        stats = Hardware::CPU::Stats.fetch

        if osx? then
          add_metric(stats.to_h)
          return
        end

        # load previous stats and store current
        prev_stats = recall(:stats)
        store(:stats => stats)

        return if prev_stats.nil?

        add_metric(stats.diff(prev_stats))
      end

    end
  end
end # Monitoring
end # Bixby

Bixby::Monitoring::CPU::Usage.new.run if $0 == __FILE__
