

module Hardware
  class CPU

    class << self

      # Get load averages as reported by 'uptime'
      #
      # @return [Hash]
      #   * "1m" [Float] last 1 minute
      #   * "5m" [Float] last 5 minutes
      #   * "15m" [Float] last 15 minutes
      def get_load
        shell = systemu("uptime")
        return nil if not shell.success?
        return parse_load(shell.stdout)
      end

      # Parse the load from the given input
      #
      # @param [String] input  result of 'uptime' command
      # @return [Hash]
      #   * "1m" [Float] last 1 minute
      #   * "5m" [Float] last 5 minutes
      #   * "15m" [Float] last 15 minutes
      def parse_load(input)
        if input !~ /load averages?: ([\d.]+)(,*) ([\d.]+)(,*) ([\d.]+)\Z/ then
          return nil
        end
        return { "1m" => $1.to_f, "5m" => $3.to_f, "15m" => $5.to_f }
      end

    end

  end
end
