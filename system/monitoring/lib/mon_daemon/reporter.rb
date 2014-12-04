
module Bixby
  module Monitoring

    # Reporter thread
    #
    # Sends collected reports back to server
    class Reporter

      include Bixby::Log

      def initialize
        @reports = []
        @report_lock = Mutex.new
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
      # @param [Array<Bixby::Monitoring::Base>] reports
      def send_reports(reports)
        return if not reports or reports.empty?

        res = Bixby::Metrics.put_check_result(reports)
        if not res.success? then
          # TODO failover to disk buffer??
          logger.error { "error reporting to server at #{Bixby.manager_uri}:\n" + res.to_s }
        end

      rescue Exception => ex
        logger.error { "error reporting to server at #{Bixby.manager_uri}: " + ex.to_s + "\n" + ex.backtrace.join("\n") }

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
            logger.info { "Sent #{queue.size} reports to server" }
          end

          sleep 30

        end # loop
      end




    end
  end
end
