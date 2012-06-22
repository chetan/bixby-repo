
require 'storage'
require 'disk_usage'

module Bixby
module Monitoring
  module Storage

    class DiskUsage < Monitoring::Base

      key "hardware.storage.disk"

      def get_options
        mounts = Hardware::Storage.list_mounts()
        return { :mount => mounts }
      end

      def monitor

        target = @options["mount"]
        if target.nil? or target.empty? then
          target = nil
        end

        df = Hardware::Storage::DiskUsage.read(target)

        skip = [:fs, :mount, :type]

        if target then
          # add metric for specific target
          add_metric(df.reject { |k,v| skip.include? k }, {:mount => target, :type => df[:type]})

        else
          # add metrics for all mounts except temporary ones
          skipfs = ["tmpfs", "devfs", "devtmpfs", "autofs"]
          df.values.each do |d|
            next if skipfs.include? d[:type]
            add_metric(d.reject { |k,v| skip.include? k }, {:mount => d[:mount], :type => d[:type]})
          end
        end
      end # monitor

    end # DiskUsage
  end # Storage
end # Monitoring
end # Bixby
