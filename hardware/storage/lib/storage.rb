
module Hardware
  module Storage

    # filesystems to ignore when returning filtered results
    SKIP_FS = ["tmpfs", "devfs", "devtmpfs", "autofs"]

    class << self

      include Bixby::PlatformUtil

      # Returns the 'df' utilities output as a hash, all sizes are in GB
      #
      # example:
      #
      # {"/" => {:fs    => "/dev/disk0s2",
      #          :size  => 297,
      #          :used  => 201,
      #          :free  => 95,
      #          :usage => 68,
      #          :mount => "/",
      #          :type  => "hfs" }}
      #
      # @param [String] fs  Specific FS mount to retrieve (optional)
      # @return [Hash] Hash of 'df' output, keyed by mount
      def disk_usage(fs=nil)

        if osx? then
          cmd = "/bin/df -gl"
        elsif linux? then
          cmd = "df -lTB G"
        end

        cmd = "#{cmd} #{fs}" if fs # append fs if passed

        shell = systemu(cmd)
        if not shell.success? then
          # TODO raise err
          return {}
        end

        ret = parse_df_output(shell.stdout)

        if osx? then
          add_mount_types(ret)
        end

        if fs and ret then
          return ret.values.first
        end

        return ret
      end

      # Parse the output of the df command
      #
      # @param [String] output    of the `df` command
      # @return [Hash] the parsed :output: as a hash
      def parse_df_output(output)
        ret = {}
        lines = output.split(/\n/)
        lines.shift # throw away header
        partial = nil
        lines.each do |line|
          if not partial.nil? then
            line = partial + " " + line
            partial = nil
          end

          if line =~ /^(\S+?|map \S+?)\s+(\d+)G?\s+(\d+)G?\s+(\d+)G?\s+(\d+)%\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.+?)$/ then
            # new mac pattern (lion+)
            ret[$9] = {
              :fs     => $1,
              :size   => $2.to_i,
              :used   => $3.to_i,
              :free   => $4.to_i,
              :usage  => $5.to_i,
              :mount  => $9
            }

          elsif line =~ /^(\S+?|map \S+?)\s+(\d+)G?\s+(\d+)G?\s+(\d+)G?\s+(\d+)%\s+(.+?)$/ then
            # old mac pattern
            ret[$6] = {
              :fs     => $1,
              :size   => $2.to_i,
              :used   => $3.to_i,
              :free   => $4.to_i,
              :usage  => $5.to_i,
              :mount  => $6
            }

          elsif line =~ /^(\S+?)\s+(\S+?)\s+(\d+)G?\s+(\d+)G?\s+(\d+)G?\s+(\d+)%\s+(.+?)$/ then
            # linux pattern
            ret[$7] = {
              :fs     => $1,
              :type   => $2,
              :size   => $3.to_i,
              :used   => $4.to_i,
              :free   => $5.to_i,
              :usage  => $6.to_i,
              :mount  => $7
            }
          elsif partial.nil? then
            partial = line

          end
        end
        return ret
      end

      # Add mount information to the given hash (mainly needed on OSX)
      def add_mount_types(hash)
        shell = systemu("mount")
        shell.stdout.split(/\n/).each do |line|
          line =~ /^(.*?) on (.*?) \((.*?),/
          if hash.include? $2 then
            hash[$2][:type] = $3
          elsif hash.include? $1 then
            hash[$1][:type] = $3
          end
        end
      end

      # Get inode usage
      #
      # Sample result:
      #
      # {"/dev/disk0s2" => {
      #     :used  => 36554943,
      #     :free  => 25749927,
      #     :usage => 59,
      #     :total => 62304870
      #   }
      # }
      #
      # @param [String] mount       mount to get metrics for (optional, defaults to all non-temp disks)
      #
      # @return [Hash] Hash of inode metrics, keyed by mount
      def inode_usage(mount=nil)

        if File.exist? "/bin/df" then
          cmd = "/bin/df -i"
        else
          cmd = osx?() ? "/bin/df -i" : "df -i"
        end

        cmd = "#{cmd} #{mount}" if mount
        shell = systemu(cmd)
        if not shell.success? then
          # TODO raise err
          return {}
        end

        lines = shell.stdout.split(/\n/)
        lines.shift # throw away header

        ret = {}
        partial = nil
        lines.each do |line|
          if not partial.nil? then
            line = partial + " " + line
            partial = nil
          end

          if line =~ /^(\S+?|map \S+?)\s+(\d+)G?\s+(\d+)G?\s+(\d+)G?\s+(\d+)%\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.+?)$/ then
            # new mac pattern (lion+)
            ret[$1] = {
              :used  => $6.to_i,
              :free  => $7.to_i,
              :usage => $8.to_i,
              :total => $6.to_i + $7.to_i
            }

          elsif line =~ /^(\S+?)\s+(\S+?)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.+?)$/ then
            # linux (gnu) pattern
            ret[$1] = {
              :used  => $3.to_i,
              :free  => $4.to_i,
              :usage => $5.to_i,
              :total => $2.to_i
            }

          elsif partial.nil? then
            partial = line

          end
        end # lines

        if osx? then
          add_mount_types(ret)
        end

        if mount and ret then
          # return single mount info
          return ret.values.first
        end

        # return info for all mounts
        return ret
      end

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
        disk_usage.values.map { |f| f[:mount] }
      end

    end # self

  end # Storage
end # Hardware
