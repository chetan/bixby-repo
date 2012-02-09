
module Monitoring
  class Base < BundleCommand

    def run

      cmd = ARGV.shift
      case cmd
      when "options"
        do_options()

      when "monitor"
        do_monitor()

      end

    end

    def do_options
      begin
        opts = get_options()
        puts opts.to_json()
        exit 0
      rescue Exception => ex
        return if ex.kind_of? SystemExit
        puts ex.message
        exit 1
      end
    end

    def do_monitor
    end

    def get_options
      raise NotImplementedError, "get_options must be overridden!", caller
    end

    def monitor
      raise NotImplementedError, "monitor must be overridden!", caller
    end

  end
end
