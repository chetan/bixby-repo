#!/usr/bin/env ruby

# monitoring daemon for ruby checks

require 'daemons'
require 'multi_json'

use_bundle "system/monitoring"

module Bixby
module Monitoring

  class Check
    attr_accessor :clazz, :options, :interval, :retry, :timeout, :storage
  end

  class MonDaemon < Bixby::Command

    def initialize()
      super

      bixby_home = ENV["BIXBY_HOME"]

      # make sure var/storage path exists
      @var = File.join(bixby_home, "var")
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

      @config_file = File.join(bixby_home, "etc", "monitoring", "config.json")
      @loaded_checks = []
      @class_map = {}
      @reports = []
      @report_lock = Mutex.new
    end

    def reload_config
      debug { "loading check config" }
      if File.exists? @config_file then
        checks = MultiJson.load(File.read(@config_file))
        load_all_checks(checks)
      else
        @loaded_checks = []
      end
      debug { "loaded #{@loaded_checks.size} check(s)" }
    end

    # Run the specified Check
    #
    # @param [Check] check
    #
    # @return [Bixby::Monitoring::Base] check instance
    def run_check(check)

      obj = check.clazz.new(check.options.dup)
      obj.storage = check.storage

      obj.monitor()
      obj.save_storage()
      check.storage = obj.storage

      return obj

    rescue Exception => ex
      error { "check failed: " + ex.to_s + "\n" + ex.backtrace.to_s }

    end

    # Send reports to master
    #
    # @param [Array<Bixby::Monitoring::Base>] reports
    def send_reports(reports)
      return if not reports or reports.empty?

      res = Bixby::Metrics.put_check_result(reports)
      if not res.success? then
        # TODO failover to disk buffer??
        error { "error reporting to server:\n" + res.to_s }
      end

    rescue Exception => ex
      error { "error reporting to server: " + ex.to_s + "\n" + ex.backtrace.to_s }

    end

    def load_all_checks(checks)

      # array of classes already loaded
      # we maintain this in order to figure out which Class was loaded during 'require'
      # a bit hacky..
      loaded_classes = @class_map.values.dup

      checks.each do |check|

        # create command and validate
        command = CommandSpec.new(check["command"])
        if not command.command_exists? then
          error { "command doesn't exist: \n" +
                  command.to_s.gsub(/^/, "\t") }
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
        opts = command.load_config() || {}
        opts.merge!(MultiJson.load(command.stdin))

        c.clazz    = @class_map[key]
        c.options  = opts
        c.interval = check["interval"]
        c.retry    = check["retry"]
        c.timeout  = check["timeout"]
        c.storage  = c.clazz.new(c.options.dup).load_storage()

        debug { "new check: #{c.clazz}" }
        @loaded_checks << c

      end # checks.each
    end # load_all_checks

    def start_reporter_thread

      # Thread for sending reports every 30 sec
      Thread.new do

        # by default we want to run this thread just after reports are
        # actually available, so we sleep for 5 sec here
        sleep 5

        loop do
          queue = nil

          @report_lock.synchronize {
            # swap reports array before submitting
            if not @reports.empty? then
              queue = @reports
              @reports = []
            end
          }

          if not (queue.nil? || queue.empty?) then
            send_reports(queue)
            debug { "sent #{queue.size} reports to server" }
          end

          sleep 30

        end # loop
      end # Thread

    end


    def run

      Daemons.run_proc('mon_daemon.rb', { :dir_mode => :normal, :dir => @var, :log_output => true }) do

        Bixby::Log.setup_logger() # new thread/proc requires logging init again

        trap("HUP") do
          # puts "caught HUP"
          reload_config()
        end

        reload_config()
        if @loaded_checks.empty? then
          $stderr.puts "no available checks"
          exit 1
        end

        debug { "starting reporter thread" }
        start_reporter_thread()

        debug { "startup complete; entering run loop" }
        # main run loop
        loop do

          # launch in separate thread so we always collect data
          # at the same time each minute
          Thread.new do
            @loaded_checks.each do |check|
              debug { "running check: #{check.clazz}" }
              ret = run_check(check)
              @report_lock.synchronize { @reports << ret }
            end
          end

          sleep 60

        end # loop

      end # Daemons

    end # run

  end # class MonDaemon

end # module Monitoring
end # module Bixby

Bixby::Monitoring::MonDaemon.new.run
