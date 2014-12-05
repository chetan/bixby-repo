
module Bixby
  module Monitoring

    class DiskBuffer

      include Bixby::Log

      def initialize(reporter)
        FileUtils.mkdir_p(disk_buffer_path)
        @reporter = reporter
      end

      def disk_buffer_path
        Bixby.path("var", "monitoring", "buffer")
      end

      def empty?
        files.empty?
      end

      def files
        Dir.glob(File.join(disk_buffer_path, "*.dump"))
      end

      # Append reports to disk buffer
      #
      # @param [Array<Hash>] reports
      def <<(reports)
        return if reports.nil? or reports.empty?

        @reporter.report_lock.synchronize {
          filename = File.join(disk_buffer_path, "#{Time.new.utc.to_i}_#{Random.rand(100000)}.dump")
          File.open(filename, "w") { |f|
            Marshal.dump(reports, f)
          }
          logger.info { "Wrote #{reports.size} reports to disk" }
        }
      end

      def flush
        logger.info { "Manager is back up; flushing disk buffers (#{files.size} reports)" }
        @reporter.report_lock.synchronize {
          files.each do |f|
            res = @reporter.send_reports(Marshal.load(File.new(f)))
            if res && res.success? then
              File.unlink(f)
            else
              logger.warn { "Stopping flush due to error" }
              return false
            end
          end
        }
        logger.info { "Completed flush" }
        true
      end

    end
  end
end
