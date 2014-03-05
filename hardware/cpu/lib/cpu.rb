

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


    class Stats
      attr_accessor :user, :system, :idle, :iowait, :interrupts, :procs_running, :procs_blocked,
                    :steal, :time

      def self.fetch
        cpu_stats = Stats.new

        if CPU.linux? then
          cpu_stats.load_linux_stats!

        elsif CPU.osx? then
          cpu_stats.load_osx_stats!
        end

        cpu_stats
      end

      def initialize
        self.time = Time.new.utc
      end

      # Load all stats on Linux systems (requires /proc/stat)
      def load_linux_stats!

        input = systemu("cat /proc/stat").stdout
        data = input.split(/\n/).collect { |line| line.split }

        if cpu = data.detect { |line| line[0] == 'cpu' }
          self.user, nice, self.system, self.idle, self.iowait,
            hardirq, softirq, self.steal = *cpu[1..-1].collect { |c| c.to_i }

          self.user   += nice
          self.system += hardirq + softirq
        end

        if interrupts = data.detect { |line| line[0] == 'intr' }
          self.interrupts, _ = *interrupts[1..-1].collect { |c| c.to_i }
        end

        if procs_running = data.detect { |line| line[0] == 'procs_running' }
          self.procs_running, _ = *procs_running[1..-1].collect { |c| c.to_i }
        end

        if procs_blocked = data.detect { |line| line[0] == 'procs_blocked' }
          self.procs_blocked, _ = *procs_blocked[1..-1].collect { |c| c.to_i }
        end
      end

      # Load user, system and idle stats for OS X
      # Other stats are unavailable on this system.
      def load_osx_stats!
        input = systemu("top -s 0 -l 1 | grep 'CPU usage'").stdout
        # "CPU usage: 8.10% user, 18.58% sys, 73.31% idle \n"

        vals = []
        input.split(/,/).each do |s|
          s =~ /([\d.]+)/
          vals << $1.to_f
        end
        self.user, self.system, self.idle = vals
      end

      def diff(other)
        diff_user   = user - other.user
        diff_system = system - other.system
        diff_idle   = idle - other.idle
        diff_iowait = iowait - other.iowait

        div   = diff_user + diff_system + diff_idle + diff_iowait
        if steal && other.steal && steal > 0
          diff_steal = steal - other.steal
          div += diff_steal
        end
        divo2 = div / 2

        results = {
          :user          => (100.0 * diff_user + divo2) / div,
          :system        => (100.0 * diff_system + divo2) / div,
          :idle          => (100.0 * diff_idle + divo2) / div,
          :iowait        => (100.0 * diff_iowait + divo2) / div,
          :procs_running => self.procs_running,
          :procs_blocked => self.procs_blocked
        }

        if diff_steal && steal > 0
          results[:steal] = (100.0 * diff_steal + divo2) / div
        end

        if self.time && other.time
          diff_in_seconds = self.time.to_f - other.time.to_f

          results[:interrupts] = (self.interrupts.to_f - other.interrupts.to_f) / diff_in_seconds
        end

        results
      end

      def to_h
        if osx? then
          {
            :user => user, :system => system, :idle => idle
          }
        elsif linux? then
          {
            :user => user, :system => system, :idle => idle, :iowait => iowait,
            :interrupts => interrupts, :procs_running => procs_running,
            :procs_blocked => procs_blocked, :steal => steal
          }
        end
      end
    end


  end
end
