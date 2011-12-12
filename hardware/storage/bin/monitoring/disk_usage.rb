#!/usr/bin/env ruby

require "disk_usage"

module Monitoring
  module Storage

    class DiskUsage < BundleCommand

      def run!

        df = Hardware::Storage::DiskUsage.read()

        # TODO transform for monitoring output
        df.values.each do |fs|
        end

      end

    end
  end
end

Monitoring::Storage::DiskUsage.new.run!

