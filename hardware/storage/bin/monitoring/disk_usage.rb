#!/usr/bin/env ruby

use_bundle "hardware/storage"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module Storage

    class DiskUsage < Monitoring::Base

      include Hardware::Storage::Monitoring

      def monitor
        super(@options["mount"], "df")
      end

    end # DiskUsage
  end # Storage
end # Monitoring
end # Bixby

Bixby::Monitoring::Storage::DiskUsage.new.run if $0 == __FILE__

