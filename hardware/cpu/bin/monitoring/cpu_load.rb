#!/usr/bin/env ruby

module Bixby
module Monitoring
  module CPU

    class LoadAverage < Bixby::Monitoring::Base

      def get_options
        return {}
      end

      def monitor
        load = Hardware::CPU.get_load()
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
