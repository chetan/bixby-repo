
module Bixby
  module Monitoring

    # Reporter thread
    #
    # Sends collected reports back to server
    class Reporter

      include Bixby::Log

      attr_reader :report_lock

      def initialize
        @reports = []
        @report_lock = Mutex.new
        @disk_buffer = DiskBuffer.new(self)
        @stopped = false
      end

      # Queue a report to be sent to the server
      #
      # @param [Hash] report
      def <<(report)
        return if !report.kind_of?(Hash)
        @report_lock.synchronize { @reports << report }
      end

      # Send reports to master
      #
      # @param [Array<Hash>] reports
      #
      # @return [JsonResponse]
      def send_reports(reports)
        return if not reports or reports.empty?

        return Bixby::Metrics.put_check_result(reports)

      rescue Exception => ex
        logger.error { "error reporting to server at #{Bixby.manager_uri}: " + ex.to_s + "\n" + ex.backtrace.join("\n") }
        return nil

      end

      def start
        logger.debug { "starting reporter thread" }
        reporter = self
        Thread.new do
          begin
            start_run_loop()
          rescue Exception => ex
            logger.error "Reporter thread run loop exited: #{ex.message}", ex
          end
        end

      end


      def start_run_loop
        # by default we want to run this thread just after reports are
        # actually available, so we sleep for 5 sec here at the start
        sleep 5

        loop do
          return if @stopped
          queue = nil

          @report_lock.synchronize {
            # swap reports array before submitting
            if not @reports.empty? then
              queue = @reports
              @reports = []
            end
          }

          if not (queue.nil? || queue.empty?) then
            res = send_reports(queue)
            if res and res.success? then
              logger.info { "Sent #{queue.size} reports to server" }
              if !@disk_buffer.empty? then
                @disk_buffer.flush
              end

            else
              logger.error { "Error reporting to server at #{Bixby.manager_uri}:\n" + res.to_s }
              @disk_buffer << queue

            end
          end

          sleep 30

        end # loop
      end

      # Stop the reporter thread
      def shutdown
        @stopped = true
        begin
          queue = nil
          @report_lock.synchronize {
            queue = @reports
            @reports = []
          }
          # flush any pending reports to disk
          if queue and not queue.empty? then
            logger.warn "Shutting down; flushing pending reports to disk"
            @disk_buffer << queue
          end
        rescue Exception => ex
          logger.error(ex)
        end
      end

    end
  end
end
