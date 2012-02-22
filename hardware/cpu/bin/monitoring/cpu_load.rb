
module Monitoring
  module CPU

    class LoadAverage < Monitoring::Base

      def configure
        @key = "hardware.cpu.loadavg"
      end

      def get_options
        return {}
      end

      def monitor
        status, stdout, stderr = systemu("uptime")
        if not status.success? or stdout !~ /load averages?: ([\d.]+)(,*) ([\d.]+)(,*) ([\d.]+)\Z/ then
          error("failed to retrieve uptime")
          return
        end
        add_metric({ "1m" => $1.to_f, "5m" => $3.to_f, "15m" => $5.to_f })
      end

    end
  end
end
