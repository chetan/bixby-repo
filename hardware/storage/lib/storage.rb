
require 'disk_usage'

module Hardware
  module Storage

    class << self

      # Gets a list of mount points on the system, as reported by 'df'
      #
      # For exmaple, given the following:
      #
      # Filesystem            Size  Used Avail Use% Mounted on
      # /dev/sda1             9.9G  4.4G  5.0G  47% /
      # none                  826M  116K  826M   1% /dev
      # /dev/sda2             147G  197M  140G   1% /mnt
      #
      # list_disks() would return:
      # ["/","/dev","/mnt"]
      #
      # @return [Array<String>] List of mount points
      def list_mounts
        mounts = []
        DiskUsage.read().values.each { |f| mounts << f[:mount] }
        return mounts
      end

    end


  end
end
