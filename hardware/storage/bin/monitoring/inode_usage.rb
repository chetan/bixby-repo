#!/usr/bin/env ruby

use_bundle "hardware/storage"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module Storage

    class InodeUsage < Monitoring::Base

      include Hardware::Storage::Monitoring

      def monitor
        super(@options["mount"], "inode")
      end

    end # InodeUsage
  end # Storage
end # Monitoring
end # Bixby

Bixby::Monitoring::Storage::InodeUsage.new.run if $0 == __FILE__
