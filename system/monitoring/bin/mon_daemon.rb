#!/usr/bin/env ruby

# monitoring daemon for ruby checks

require 'daemons'
require 'json'

module Monitoring

  class Check
    attr_accessor :clazz, :options, :interval, :retry, :timeout
  end

  class MonDaemon < BundleCommand

    def initialize
      super(false)
      @var = "#{DEVOPS_ROOT}/var"
      system("mkdir -p #{@var}")

      @config_file = "#{DEVOPS_ROOT}/etc/monitoring/config.json"
      @loaded_checks = {}
      @reports = []
    end

    def reload_config
      if File.exists? @config_file then
        checks = JSON.parse(File.read(@config_file))
        load_all_checks(checks)
      else
        @loaded_checks = {}
      end
    end

    # Run the specified Check
    #
    # @param [Check] check
    def run_check(check)

      obj = check.clazz.new(check.options.dup)

      obj.monitor()
      obj.status == "OK" if obj.status.nil?

      @reports << obj
    end

    def send_reports
      req = JsonRequest.new("metrics:put_check_result", [ @reports ])
      res = req.exec()

      if not res.success? then
        # TODO failover to disk buffer??
        puts "error reporting to server:"
        puts res
      end

      @reports.clear
    end

    def load_all_checks(checks)
      checks.each do |check|

        # create command and validate
        command = CommandSpec.new(check["command"])
        begin
          command.validate()
        rescue Exception => ex
          puts "error loading check: #{command}"
          puts ex
          return
        end

        next if command.command !~ /\.rb$/ # skip non-ruby checks

        # require script if necessary
        key = command.bundle + "/" + command.command
        if not @loaded_checks.include? key then
          # puts "loading #{key}"
          lib = "#{command.bundle_dir}/lib"
          $: << lib if not $:.include? lib
          require command.command_file

          clazz = Monitoring::Base.subclasses.find{ |s| @loaded_checks.values.find{ |l| l.clazz != s }.nil? }
          # puts "found class #{clazz}"

          c = Check.new
          c.clazz    = clazz
          c.options  = JSON.parse(command.stdin)
          c.interval = check["interval"]
          c.retry    = check["retry"]
          c.timeout  = check["timeout"]
          @loaded_checks[key] = c
        end

      end
    end

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

          @loaded_checks.values.each do |check|
            run_check(check)
          end
          send_reports()

          sleep 60

        end # loop

      end # Daemons

    end # run

  end # class MonDaemon

end # module Monitoring

