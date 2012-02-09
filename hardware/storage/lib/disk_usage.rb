
module Hardware
  module Storage
    class DiskUsage

      class << self

        include BundleUtil

        # Returns the 'df' utilities output as a hash, all sizes are in GB
        #
        # example:
        #
        # {"/dev/disk0s2"=>{:fs=>"/dev/disk0s2", :size=>297, :used=>201, :free=>95, :usage=>68, :mount=>"/"}}
        #
        # @return [Hash] Hash of 'df' output
        def read(fs=nil)

          if osx? then
            cmd = "/bin/df -g"
          elsif linux? then
            cmd = "df -B G"
          end

          status, stdout, stderr = systemu(cmd)
          if not status.success? then
            # TODO raise err
          end

          return parse_output(stdout)
        end

        # @return [Hash] the parsed :output: as a hash
        def parse_output(output)
          ret = {}
          lines = output.split(/\n/)
          lines.shift
          partial = nil
          lines.each do |line|
            if not partial.nil? then
              line = partial + " " + line
              partial = nil
            end
            if line =~ /^(\S+?)\s+(\d+)G?\s+(\d+)G?\s+(\d+)G?\s+(\d+)%\s+(.+?)$/ then
              ret[$1] = {
                :fs     => $1,
                :size   => $2.to_i,
                :used   => $3.to_i,
                :free   => $4.to_i,
                :usage  => $5.to_i,
                :mount  => $6
              }
            elsif partial.nil? then
              partial = line

            end
          end
          return ret
        end

      end

    end
  end
end
