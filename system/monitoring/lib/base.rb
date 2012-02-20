
module Monitoring

  ERROR    = "ERROR"
  TIMEOUT  = "TIMEOUT"
  CRITICAL = "CRITICAL"
  WARNING  = "WARNING"
  UNKNOWN  = "UNKNOWN"
  OK       = "OK"

  class Base < BundleCommand

    attr_accessor :status, :errors

    # Create new instance
    #
    # @param config [Hash] Hash of command metadata
    def initialize(cmd, options, config = nil)
      @cmd = cmd
      @options = options
      @timestamp = Time.new.to_i
      @metrics = {}
      @metadata = {}
      @errors = []
      @status = nil

      return if config.nil?
      @key = config["key"]
    end

    def run

      case @cmd
      when "options"
        do_options()

      when "monitor"
        do_monitor()

      end

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
    def add_metric(metrics)
      @metrics.merge!(metrics)
    end

    # Add metadata to be reported
    # @param [Hash] metadata  key/value pairs to report
    def add_metadata(metadata)
      @metadata.merge!(metadata)
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
      skip = [ :@options, :@cmd ]
      super.reject { |j| skip.include? j }
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

  end
end
