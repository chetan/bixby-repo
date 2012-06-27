
module Bixby
module Monitoring

  ERROR    = "ERROR"
  TIMEOUT  = "TIMEOUT"
  CRITICAL = "CRITICAL"
  WARNING  = "WARNING"
  UNKNOWN  = "UNKNOWN"
  OK       = "OK"

  class Base < BundleCommand

    attr_accessor :status, :errors, :storage

    option :monitor,
      :short          => "-m",
      :long           => "--monitor",
      :description    => "Retrieve metrics",
      :boolean        => true

    option :options,
      :short          => "-o",
      :long           => "--options",
      :description    => "List options used by plugin",
      :boolean        => true

    # Create new instance
    #
    # @param config [Hash] Hash of command metadata
    def initialize(options=nil)
      super

      @cmd = if @config[:monitor] then
        "monitor"
      elsif @config[:options] then
        "options"
      else
        "monitor" # default
      end

      @storage = {}
      @options = options || get_json_input()
      @key = options["key"]
      @check_id = options ? options["check_id"] : nil
      reset()
      configure()
    end

    # Reset the check. Called during #initialize and before #monitor
    def reset
      @timestamp = Time.new.to_i
      @metrics = []
      @errors = []
      @status = nil
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
      raise NotImplementedError, "get_options must be overridden!", caller
    end

    def monitor
      raise NotImplementedError, "monitor must be overridden!", caller
    end

    # Add metrics to be reported
    #
    # @param [Hash] metrics  key/value pairs to report
    # @param [Hash] metadata  key/value pairs to report
    def add_metric(metrics, metadata={})
      @metrics << { :metrics => metrics, :metadata => metadata }
    end

    # Set error message and status
    #
    # @param msg [String] Error message
    # @param status [String] Status code (defaults to ERROR)
    def error(msg, status=ERROR)
      @errors << msg
      @status = status
    end

    # Store the given data for the next run
    #
    # @param [Hash] hash  data to store
    def store(hash)
      return if hash.nil?
      @storage.merge(hash)
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

    def storage_path
      File.join(BIXBY_HOME, "var", "monitoring", "data", "#{@key}.dump")
    end

    def save_storage
      puts "saving storage.."
      puts storage_path
      systemu("mkdir -p " + File.dirname(storage_path))
      f = File.new(storage_path, 'w')
      Marshal.dump(@storage, f)
      f.flush
      f.close
    end

    def load_storage
      if File.exist? storage_path then
        Marshal.load(File.new(storage_path))
      end
    end

    def to_hash
      fields = [ :@timestamp, :@status, :@check_id, :@key, :@metrics, :@errors ]
      fields.inject({}) { |m,v| m[v[1,v.length].to_sym] = instance_variable_get(v); m }
    end

    private


    def do_options
      begin
        opts = get_options()
        puts MultiJson.dump(opts)
        exit 0
      rescue Exception => ex
        return if ex.kind_of? SystemExit
        puts ex.message
        exit 1
      end
    end

    def do_monitor
      begin
        @storage = load_storage() || {}
        monitor()
        @status = OK if @status.nil?
        puts MultiJson.dump(self.to_hash)
        exit 0
      rescue Exception => ex
        return if ex.kind_of? SystemExit
        @errors << ex.message
        @errors << ex.backtrace.join("\n")
        @status = ERROR if @status.nil?
        puts MultiJson.dump(self.to_hash)
        exit 1
      end
    end

    def self.inherited(subclass)
      super
      subclass.extend(Monitoring::Base::ClassMethods)
      if superclass.respond_to? :inherited
        superclass.inherited(subclass)
      end
    end

  end # Base

end # Monitoring
end # Bixby
