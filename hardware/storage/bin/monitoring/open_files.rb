#!/usr/bin/env ruby

use_bundle "system/monitoring"
use_bundle "hardware/storage"

module Bixby
module Monitoring
  module Storage

    class OpenFiles < Monitoring::Base

      def monitor

        cmd = systemu("lsof -n | wc -l")
        ret = {
          :count => cmd.stdout.to_i
        }

        if linux? then
          ret[:max] = systemu("cat /proc/sys/fs/file-nr | awk '{print $3}'").stdout.to_i
        elsif darwin? then
          ret[:max] = systemu("launchctl limit maxfiles | awk '{print $3}'").stdout.to_i
        end

        add_metrics ret
      end

    end # OpenFiles
  end # Storage
end # Monitoring
end # Bixby

Bixby::Monitoring::Base.subclasses.last.new.run if $0 == __FILE__
