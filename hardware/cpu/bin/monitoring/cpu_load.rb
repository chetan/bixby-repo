
module Monitoring
  module CPU

    class LoadAverage < Monitoring::Base

      key "hardware.cpu.loadavg"

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
end
