#!/usr/bin/env ruby

use_bundle "hardware/storage"
use_bundle "system/monitoring"

module Bixby
module Monitoring
  module Storage

    class DiskUsage < Monitoring::Base

      def get_options
        return { :device => Hardware::Storage.list_devices() }
      end

      def monitor

        target = @options["mount"]
        if target.nil? or target.empty? then
          target = nil
        end

        df = Hardware::Storage.inode_usage()

        skip = [:fs, :mount, :type]

        if target then
          # add metric for specific target
          add_metric(df.reject { |k,v| skip.include? k }, {:device => target})

        else
          # add metrics for all mounts except temporary ones
          skipfs = ["tmpfs", "devfs", "devtmpfs", "autofs"]
          df.each do |device, d|
            next if skipfs.include? d[:type]
            add_metric(d.reject { |k,v| skip.include? k }, {:device => device})
          end
        end
      end # monitor

    end # DiskUsage
  end # Storage
end # Monitoring
end # Bixby

Bixby::Monitoring::Storage::DiskUsage.new.run if $0 == __FILE__
