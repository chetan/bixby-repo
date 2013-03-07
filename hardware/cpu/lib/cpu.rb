

module Hardware
  class CPU

    class << self

      include Bixby::PlatformUtil

      # Get load averages as reported by 'uptime'
      #
      # @param [Fixnum] num_processors      num_processors
      #
      # @return [Hash]
      #   * "1m" [Float] last 1 minute
      #   * "5m" [Float] last 5 minutes
      #   * "15m" [Float] last 15 minutes
      def get_load(num_processors)
        shell = systemu("uptime")
        return nil if not shell.success?
        return parse_load(shell.stdout, num_processors)
      end

      # Parse the load from the given input
      #
      # @param [String] input               result of 'uptime' command
      # @param [Fixnum] num_processors      num_processors
      #
      # @return [Hash]
      #   * "1m" [Float] last 1 minute
      #   * "5m" [Float] last 5 minutes
      #   * "15m" [Float] last 15 minutes
      def parse_load(input, num_processors)
        if input !~ /load averages?: ([\d.]+)(,*) ([\d.]+)(,*) ([\d.]+)\Z/ then
          return nil
        end
        return { "1m" => $1.to_f/num_processors, "5m" => $3.to_f/num_processors, "15m" => $5.to_f/num_processors }
      end

      # Get the number of processor cores in the system
      #
      # @return [Fixnum]
      def num_processors
        if linux? then
          shell = systemu("cat /proc/cpuinfo | grep 'model name' | wc -l")
          raise "failed to lookup num cpus" if not(shell.success? && shell.stdout =~ /(\d+)/)
          return $1.to_i

        elsif osx? then
          shell = systemu("hostinfo | grep physical | egrep -o '^[0-9]+'")
          raise "hostinfo failed" if not shell.success?
          return shell.stdout.strip.to_i

        end
        raise "unknown OS"
      end

    end

  end
end
