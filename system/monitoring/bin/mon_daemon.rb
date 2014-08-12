#!/usr/bin/env ruby

# monitoring daemon for ruby checks

require 'daemons'
require 'multi_json'

use_bundle "system/general"
use_bundle "system/monitoring"

require "mon_daemon/check"
require "mon_daemon/reporter"

module Bixby
module Monitoring

  class MonDaemon < Bixby::Command

    def initialize()
      super
      @var = Bixby.path("var")
      @config_file = Bixby.path("etc", "monitoring", "config.json")
      @loaded_checks = []
      @class_map = {}
      @reporter = Reporter.new
    end

    def reload_config
      logger.debug { "loading check config" }
      if File.exists? @config_file then
        begin
          checks = MultiJson.load(File.read(@config_file))
        rescue MultiJson::LoadError => ex
          logger.error "Error reading config from #{@config_file}"
          logger.error ex
          $stderr.puts "Error reading config from #{@config_file}; exiting (pid #{$$})"
          exit 1
        end
        load_all_checks(checks)
      else
        @loaded_checks = []
      end
      logger.debug { "loaded #{@loaded_checks.size} check(s)" }
    end

    # Run the specified Check
    #
    # @param [Check] check
    #
    # @return [Hash] hash of results
    def run_check(check)
      logger.debug { "running check: #{check.clazz}" }

      obj = check.clazz.new(check.options.dup, check.config.dup)
      obj.storage = check.storage

      obj.monitor()
      obj.save_storage()
      check.storage = obj.storage

      return obj.to_hash

    rescue Exception => ex
      logger.error { "check failed: " + ex.to_s + "\n" + ex.backtrace.join("\n") }

    end

    # Load all configured checks and their options
    def load_all_checks(checks)

      # array of classes already loaded
      # we maintain this in order to figure out which Class was loaded during 'require'
      # a bit hacky..
      loaded_classes = @class_map.values.dup

      checks.each do |check|

        # create command and validate
        command = CommandSpec.new(check["command"])
        if not command.command_exists? then
          logger.error { "command doesn't exist: \n" + command.to_s.gsub(/^/, "\t") }
          next
        end

        next if command.command !~ /\.rb$/ # FIXME skip non-ruby checks

        # require script if necessary
        Bixby.use_bundle(command.bundle)
        key = command.bundle + "/" + command.command
        if not @class_map.include? key then
          require command.command_file

          subclasses = Monitoring::Base.subclasses - loaded_classes
          clazz = subclasses.last
          loaded_classes << clazz
          @class_map[key] = clazz
        end

        # instantiate the Check
        c = Check.new

        # merge command options with ones passed in from manager (check_id)
        config = command.load_config() || {}
        opts = MultiJson.load(command.stdin)

        c.clazz    = @class_map[key]
        c.options  = opts
        c.config   = config
        c.interval = check["interval"]
        c.retry    = check["retry"]
        c.timeout  = check["timeout"]
        c.storage  = c.clazz.new(c.options.dup, c.config.dup).load_storage()

        logger.debug { "new check: #{c.clazz}" }
        @loaded_checks << c

      end # checks.each
    end # load_all_checks


    # Run the daemon
    def run

      app_name = "bixby-monitoring-daemon"
      starter = Bixby::DaemonStarter.new(@var, app_name)
      return if not starter.start?

      opts = {
        :dir_mode   => :normal,
        :dir        => @var,
        :log_output => true,
        :multiple   => false
      }
      Daemons.run_proc(app_name, opts) do

        starter.cleanup!
        create_data_dir()
        Logging.reopen

        trap("HUP") do
          # puts "caught HUP"
          reload_config()
          return
        end

        reload_config()
        if @loaded_checks.empty? then
          $stderr.puts "no available checks"
          exit 1
        end

        @reporter.start()

        logger.debug { "startup complete; entering run loop" }
        # main run loop
        loop do

          # launch in separate thread so we always collect data
          # at the same time each minute
          Thread.new do
            @loaded_checks.each do |check|
              begin
                @reporter << run_check(check)
              rescue Exception => ex
                logger.error "Caught exception running check (#{check.clazz}): " +
                  "#{ex.message}\n#{ex.backtrace.join('\n')}"
              end
            end
          end

          sleep 60

        end # loop

      end # Daemons
      starter.cleanup! if Daemons.controller.error?

    end # run


    private

    def create_data_dir
      # make sure var/storage path exists
      d = File.join(@var, "monitoring", "data")
      if not File.directory? d then
        begin
          FileUtils.mkdir_p(d)
        rescue Exception => ex
          $stderr.puts "unable to create dir #{d}"
          $stderr.puts "  #{ex.message}"
          exit 1
        end
      end
    end


  end # class MonDaemon

end # module Monitoring
end # module Bixby

Bixby::Monitoring::MonDaemon.new.run
