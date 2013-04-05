
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
    def option(key)
      @options[key.to_s]
    end

    def report(metrics)
      if @config["rename"] then
        @config["rename"].each do |old_key, new_key|
          metrics[new_key.to_sym] = metrics.delete(old_key.to_sym)
        end
      end
      add_metric(metrics)
    end

    def alert(subj, body=nil)
      error(subj)
      error(body) if not body.nil?
    end

  end
end
