
module Hardware
  module Storage
    class DiskUsage

      class << self

        include Bixby::BundleUtil

        # Returns the 'df' utilities output as a hash, all sizes are in GB
        #
        # example:
        #
        # {"/" => {:fs=>"/dev/disk0s2", :size=>297, :used=>201, :free=>95, :usage=>68, :mount=>"/", :type => "hfs"}}
        #
        # @param [String] fs  Specific FS mount to retrieve (optional)
        # @return [Hash] Hash of 'df' output, keyed by mount
        def read(fs=nil)

          if osx? then
            cmd = "/bin/df -gl"
          elsif linux? then
            cmd = "df -lTB G"
          end

          cmd = "#{cmd} #{fs}" if fs # append fs if passed

          status, stdout, stderr = systemu(cmd)
          if not status.success? then
            # TODO raise err
          end

          ret = parse_output(stdout)

          if osx? then
            add_mount_types(ret)
          end

          if fs and ret then
            return ret.values.first
          end

          return ret
        end

        # @return [Hash] the parsed :output: as a hash
        def parse_output(output)
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

        def add_mount_types(hash)
          status, stdout, stderr = systemu("mount")
          stdout.split(/\n/).each do |line|
            line =~ /^(.*?) on (.*?) \((.*?),/
            if hash.include? $2 then
              hash[$2][:type] = $3
            end
          end
        end

      end

    end
  end
end
