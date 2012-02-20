#!/usr/bin/env ruby

module Monitoring
  module Storage

    class DiskUsage < Monitoring::Base

      def get_options
        mounts = Hardware::Storage.list_disks()
        return { :filesystem => mounts }
      end

      def monitor

        target = @options["filesystem"]
        if target.nil? or target.empty? then
          return error("filesystem is required")
        end

        df = Hardware::Storage::DiskUsage.read(target)
        if df.nil? then
          return error("filesystem '#{target}' not found")
        end

        add_metadata(:filesystem => target, :type => df[:type])

        skip = [:fs, :mount, :type]
        add_metric(df.reject { |k,v| skip.include? k })
      end

    end
  end
end
