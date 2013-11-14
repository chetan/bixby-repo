#!/usr/bin/env ruby

use_bundle "hardware/storage"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module Storage

    class DiskUsage < Monitoring::Base

      # filesystems to ignore
      SKIP_FS = ["tmpfs", "devfs", "devtmpfs", "autofs"]

      # keys to skip when outputting usage
      SKIP_KEYS = [:fs, :mount, :type]

      # List available mounts, ignoring non-physical types
      def get_options
        mounts = []
        Hardware::Storage.disk_usage.values.each do |disk|
          mounts << disk[:mount] if !SKIP_FS.include? disk[:type]
        end
        return { :mount => mounts }
      end

      def monitor

        target = @options["mount"]
        if target.nil? or target.empty? then
          target = nil
        end

        df = Hardware::Storage.disk_usage(target)

        if target then
          # add metric for specific target
          add_metric(df.reject { |k,v| SKIP_KEYS.include? k }, {:mount => target, :type => df[:type]})

        else
          # add metrics for all mounts except temporary ones
          df.values.each do |d|
            next if SKIP_FS.include? d[:type]
            add_metric(d.reject { |k,v| SKIP_KEYS.include? k }, {:mount => d[:mount], :type => d[:type]})
          end
        end
      end # monitor

    end # DiskUsage
  end # Storage
end # Monitoring
end # Bixby

Bixby::Monitoring::Storage::DiskUsage.new.run if $0 == __FILE__

