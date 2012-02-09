#!/usr/bin/env ruby

module Monitoring
  module Storage

    class DiskUsage < Monitoring::Base

      def get_options
        mounts = Hardware::Storage.list_disks()
        opts = { :filesystem => mounts }
        return opts
      end

      def monitor
        df = Hardware::Storage::DiskUsage.read()

        # TODO transform for monitoring output
        df.values.each do |fs|
        end
      end

    end
  end
end
