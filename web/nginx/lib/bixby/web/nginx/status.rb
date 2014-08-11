
require "httpi"
HTTPI.log = false

module Bixby
  module Web
    module Nginx
      module Status

        class Stats
          attr_accessor :active_conns, :accepted_conns, :handled_conns, :requests,
                        :reading, :writing, :waiting

          # Expects nginx status of the form:
          #
          # Active connections: 1
          # server accepts handled requests
          #  33 33 33
          # Reading: 0 Writing: 1 Waiting: 0
          #
          #
          # @param [String] status        as above example
          #
          # @return [Stats]
          def initialize(status)
            lines = status.split(/\n/)

            if lines.shift =~ /^Active connections:\s+(\d+)/ then
              @active_conns = $1.to_i
            end
            lines.shift
            (@accepted_conns, @handled_conns, @requests) = lines.shift.split(/\s+/).reject{ |s| s.empty? }.map{ |s| s.to_i }
            if lines.shift =~ /^Reading:\s+(\d+).*Writing:\s+(\d+).*Waiting:\s+(\d+)/ then
              @reading = $1.to_i
              @writing = $2.to_i
              @waiting = $3.to_i
            end
          end

          def to_hash
            hash = {}
            [:active_conns, :accepted_conns, :handled_conns, :requests,
              :reading, :writing, :waiting].each{ |s| hash[s] = self.send(s) }
            return hash
          end

        end

        def read_status(url)

          res = HTTPI.get(url)
          if res.error? then
            raise "Error reading status, #{url} returned #{res.code}"
          end

          return Stats.new(res.body)
        end

      end
    end
  end
end
