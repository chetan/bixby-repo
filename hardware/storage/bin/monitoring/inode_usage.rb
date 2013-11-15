#!/usr/bin/env ruby

use_bundle "hardware/storage"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module Storage

    class InodeUsage < Monitoring::Base

      def get_options
        mounts = []
        Hardware::Storage.disk_usage.values.each do |disk|
          mounts << disk[:mount] if !Hardware::Storage::SKIP_FS.include? disk[:type]
        end
        return { :mount => mounts }
      end

      def monitor

        target = @options["mount"]
        if target.nil? or target.empty? then
          target = nil
        end

        df = Hardware::Storage.inode_usage(target)

        skip = [:fs, :mount, :type]

        if target then
          # add metric for specific target
          add_metric(df.reject { |k,v| skip.include? k }, {:mount => target})

        else
          # add metrics for all mounts except temporary ones
          skipfs = ["tmpfs", "devfs", "devtmpfs", "autofs"]
          df.each do |mount, d|
            next if skipfs.include? d[:type]
            add_metric(d.reject { |k,v| skip.include? k }, {:mount => mount})
          end
        end
      end # monitor

    end # InodeUsage
  end # Storage
end # Monitoring
end # Bixby

Bixby::Monitoring::Storage::InodeUsage.new.run if $0 == __FILE__
