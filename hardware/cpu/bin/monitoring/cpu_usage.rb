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
      end

    end
  end
end # Monitoring
end # Bixby

Bixby::Monitoring::CPU::Usage.new.run if $0 == __FILE__
