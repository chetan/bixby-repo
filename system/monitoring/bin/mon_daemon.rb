#!/usr/bin/env ruby

# monitoring daemon for ruby checks

require 'daemons'
require 'multi_json'

module Bixby
module Monitoring

  class Check
    attr_accessor :clazz, :options, :interval, :retry, :timeout, :storage
  end

  class MonDaemon < BundleCommand

    def initialize(options=nil)
      @skip_parse = true
      super


      # make sure var/storage path exists
      @var = File.join(BIXBY_HOME, "var")
      d = File.join(@var, "monitoring", "data")
      if not File.directory? d then
        begin
          FileUtils.mkdir_p(d)
        rescue Exception => ex
          STDERR.puts "unable to create dir #{d}"
          STDERR.puts "  #{ex.message}"
          exit 1
        end
      end

      @config_file = "#{BIXBY_HOME}/etc/monitoring/config.json"
      @loaded_checks = []
      @class_map = {}
      @reports = []
    end

    def reload_config
      if File.exists? @config_file then
        checks = MultiJson.load(File.read(@config_file))
        load_all_checks(checks)
      else
        @loaded_checks = []
      end
    end

    # Run the specified Check
    #
    # @param [Check] check
    def run_check(check)

      obj = check.clazz.new(check.options.dup)
      obj.storage = check.storage

      obj.monitor()
      obj.status == "OK" if obj.status.nil?

      obj.save_storage()
      check.storage = obj.storage

      @reports << obj
    end

    def send_reports
      req = JsonRequest.new("metrics:put_check_result", [ @reports ])
      res = @agent.exec_api(req)

      if not res.success? then
        # TODO failover to disk buffer??
        puts "error reporting to server:"
        puts res
      end

      @reports.clear
    end

    def load_all_checks(checks)

      # array of classes already loaded
      # we maintain this in order to figure out which Class was loaded during 'require'
      # a bit hacky..
      loaded_classes = @class_map.values.dup

      checks.each do |check|

        puts "looking at check"
        p check

        # create command and validate
        command = CommandSpec.new(check["command"])
        if not command.command_exists? then
          puts "command doesn't exist: "
          puts command.to_s.gsub(/^/, "\t")
          next
        end

        next if command.command !~ /\.rb$/ # FIXME skip non-ruby checks

        # require script if necessary
        key = command.bundle + "/" + command.command
        if not @class_map.include? key then
          # puts "loading #{key}"
          lib = "#{command.bundle_dir}/lib"
          $:.unshift(lib) if File.directory? lib and not $:.include? lib
          # puts "require #{command.command_file}"
          require command.command_file

          subclasses = Monitoring::Base.subclasses - loaded_classes
          clazz = subclasses.first
          loaded_classes << clazz
          @class_map[key] = clazz
        end

        # instantiate the Check
        c = Check.new

        # merge command options with ones passed in from manager (check_id)
        opts = command.load_config() || {}
        opts.merge!(MultiJson.load(command.stdin))

        c.clazz    = @class_map[key]
        c.options  = opts
        c.interval = check["interval"]
        c.retry    = check["retry"]
        c.timeout  = check["timeout"]
        c.storage  = c.clazz.new(c.options.dup).load_storage()

        @loaded_checks << c

      end # checks.each
    end # load_all_checks

    def run

      Daemons.run_proc('mon_daemon.rb', { :dir_mode => :normal, :dir => @var, :log_output => true }) do

        trap("HUP") do
          # puts "caught HUP"
          reload_config()
        end

        reload_config()
        if @loaded_checks.empty? then
          STDERR.puts "no available checks"
          exit 1
        end

        loop do

          @loaded_checks.each do |check|
            run_check(check)
          end
          send_reports()

          sleep 60

        end # loop

      end # Daemons

    end # run

  end # class MonDaemon

end # module Monitoring
end # module Bixby
