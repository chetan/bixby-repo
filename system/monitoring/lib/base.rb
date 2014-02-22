
module Bixby
module Monitoring

  ERROR    = "ERROR"
  TIMEOUT  = "TIMEOUT"
  CRITICAL = "CRITICAL"
  WARNING  = "WARNING"
  UNKNOWN  = "UNKNOWN"
  OK       = "OK"

  class Base < Bixby::Command

    attr_accessor :status, :errors, :storage

    # Create new instance
    #
    # @param [Hash] options      Hash of command metadata
    def initialize(options=nil)
      super()

      @config = load_config()
      @options = @config.merge(options || get_json_input())

      @storage = {}
      @key = @options["key"]
      @check_id = @options ? @options["check_id"] : nil
      reset()
      configure()

      cmd = ARGV.shift
      @cmd = if cmd.nil? or cmd.empty? or cmd == "--monitor" then
        "monitor"
      elsif cmd == "--options" then
        "options"
      end
    end

    # Reset the check. Called during #initialize and before #monitor
    def reset
      @timestamp = Time.new.utc.to_i
      @metrics = []
      @errors = []
      @status = OK
    end

    def run

      case @cmd
      when "options"
        do_options()

      when "monitor"
        do_monitor()

      end

    end

    # Configure your check. Called during initialize()
    def configure
    end

    def get_options
      return {}
    end

    def monitor
      raise NotImplementedError, "monitor must be overridden!", caller
    end

    # Get an option
    #
    # @param [String] key
    # @return [Object] value
    def option(key)
      @options[key.to_s]
    end

    # Add metrics to be reported
    #
    # @param [Hash] metrics  key/value pairs to report
    # @param [Hash] metadata  key/value pairs to report
    def add_metric(metrics, metadata={})

      # convert booleans to integer values
      metrics.each do |k,v|
        if v == true then
          metrics[k] = 1
        elsif v == false then
          metrics[k] = 0
        end
      end

      @metrics << { :metrics => metrics, :metadata => metadata }
    end
    alias_method :add_metrics, :add_metric

    # Set error message and status
    #
    # @param msg [String] Error message
    # @param status [String] Status code (default: ERROR)
    def error(msg, status=nil)
      if msg.kind_of? Exception then
        msg = msg.message + "\n" + msg.backtrace.join("\n")
      elsif not msg.kind_of? String then
        msg = msg.to_s
      end
      status ||= ERROR
      @errors << msg
      @status = status if not status.nil?
    end

    # Store the given data for the next run
    #
    # @param [Hash] hash  data to store
    def store(hash)
      return if hash.nil?
      @storage.merge!(hash)
    end
    alias_method :remember, :store
    alias_method :keep, :store

    # Recall the value of a stored key, if available
    #
    # @param [String, Symbol] key
    # @return [Object] stored data
    def recall(key)
      return @storage[key.to_s] if @storage.include? key.to_s
      return @storage[key.to_sym] if @storage.include? key.to_sym
      return nil
    end
    alias_method :memory, :recall

    # Retrieves the given key from storage. If key is not present, the given
    # block is called and it's value stored with the given key.
    #
    # @param [String, Symbol] key
    # @param [Block] code to generate value
    #
    # @return [Object] stored data
    def memoize(key, &block)
      if @storage.include? key then
        return @storage[key]
      end

      val = block.call()
      store(key => val)
      return val
    end

    # Filename where data will be stored
    def storage_path
      Bixby.path("var", "monitoring", "data", "#{@key}.dump")
    end

    # Save storage hash to disk.
    def save_storage
      dir = File.dirname(storage_path)
      if not File.directory? dir then
        FileUtils.mkdir_p(dir)
      end
      File.open(storage_path, 'w') do |f|
        Marshal.dump(@storage, f)
      end
    end

    # Try to load storage hash from disk. Defaults to empty hash
    #
    # @return [Hash]
    def load_storage
      if File.exist? storage_path then
        begin
          return Marshal.load(File.new(storage_path))
        rescue Exception => ex
        end
      end
      return {}
    end

    def to_hash
      fields = [ :@timestamp, :@status, :@check_id, :@key, :@metrics, :@errors ]
      fields.inject({}) { |m,v| m[v[1,v.length].to_sym] = instance_variable_get(v); m }
    end

    private


    def do_options
      begin
        opts = get_options() || {}
        puts MultiJson.dump(opts)
      rescue Exception => ex
        puts ex.message
        exit 1
      end
      exit 0
    end

    def do_monitor
      begin
        @storage = load_storage()
        monitor()
        puts MultiJson.dump(self.to_hash)
        save_storage()
      rescue Exception => ex
        @errors << ex.message
        @errors << ex.backtrace.join("\n")
        @status = ERROR if @status.nil?
        puts MultiJson.dump(self.to_hash)
        save_storage()
        exit 1
      end
      exit 0
    end

    def load_config
      file = "#{$0}.json"
      if File.exist? file
        return MultiJson.load(File.read(file))
      end
      return {}
    end

  end # Base

end # Monitoring
end # Bixby

# load our Scout::Plugin shim
require File.join(File.dirname(__FILE__), "scout_shim")
