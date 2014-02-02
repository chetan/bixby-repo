
module Bixby
  module Monitoring

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
        @report_lock.synchronize { @reports << ret }
      end

      # Send reports to master
      #
      # @param [Array<Bixby::Monitoring::Base>] reports
      def send_reports(reports)
        return if not reports or reports.empty?

        res = Bixby::Metrics.put_check_result(reports)
        if not res.success? then
          # TODO failover to disk buffer??
          logger.error { "error reporting to server:\n" + res.to_s }
        end

      rescue Exception => ex
        logger.error { "error reporting to server: " + ex.to_s + "\n" + ex.backtrace.to_s }

      end

      def start
        logger.debug { "starting reporter thread" }
        reporter = self
        Thread.new do
          begin
            run_loop()
          rescue Exception => ex
            logger.error "Reporter thread run loop exited: #{ex.message}", ex
          end
        end

      end


      def run_loop
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
            logger.debug { "sent #{queue.size} reports to server" }
          end

          sleep 30

        end # loop
      end




    end
  end
end
