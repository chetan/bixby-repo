
module Monitoring

  ERROR    = "ERROR"
  TIMEOUT  = "TIMEOUT"
  CRITICAL = "CRITICAL"
  WARNING  = "WARNING"
  UNKNOWN  = "UNKNOWN"
  OK       = "OK"

  class Base < BundleCommand

    module ClassMethods
      attr_accessor :key
      def key(val=nil)
        if not val.nil? then
          @key = val
        end
        @key
      end
    end

    attr_accessor :status, :errors

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
      super(true)

      @cmd = if @config[:monitor] then
        "monitor"
      elsif @config[:options] then
        "options"
      else
        "monitor" # default
      end

      @key = self.class.key
      @options = options || get_json_input()
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

    # Configure your base class. Called during initialize()
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

    def to_json_properties
      [ :@timestamp, :@status, :@check_id, :@key, :@metrics, :@errors ]
    end

    private


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
      begin
        monitor()
        @status = OK if @status.nil?
        puts self.to_json()
        exit 0
      rescue Exception => ex
        return if ex.kind_of? SystemExit
        @errors << ex.message
        @errors << ex.backtrace.join("\n")
        @status = ERROR if @status.nil?
        puts self.to_json()
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

  end
end
