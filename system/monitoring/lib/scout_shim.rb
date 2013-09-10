
require File.join(File.dirname(File.expand_path(__FILE__)), "base")

module Scout
  class Plugin < Bixby::Monitoring::Base

    def configure
      # need to load options or not?
      # opts = YAML.load(self.class::OPTIONS)
      # opts.keys.each do |key|
      #   if opts[key]["default"] and not @options.include? key then
      #     @options[key] = opts[key]["default"]
      #   end
      # end
    end

    def get_options
      # TODO not supported by scout plugins - throw error?
      {}
    end

    def monitor
      build_report()
    end

    # implement scout plugin api
    def report(metrics)
      if @config["rename"] then
        @config["rename"].each do |old_key, new_key|
          metrics[new_key.to_sym] = metrics.delete(old_key.to_sym)
        end
      end
      add_metric(metrics)
    end
    alias_method :add_report, :report

    def alert(*args)
      error(*args)
    end
    alias_method :add_alert, :alert

    def error(*args)
      if args.first.kind_of? Hash then
        super(args[:subject])
        super(args[:body])
      else
        # assume list of error messages received
        args.each{ |msg| super(msg) }
      end
    end
    alias_method :add_error, :error

    def needs(*libs)
      libs.each do |lib|
        begin
          require library
        rescue LoadError
          error("Could not load library #{library}")
          return false
        end
      end
    end

    # not supported currently
    def summary(*args)
    end
    alias_method :add_summary, :summary

  end
end
