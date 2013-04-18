#!/usr/bin/env ruby

use_bundle "system/monitoring"

class ConnectionState < Bixby::Monitoring::Base

  def monitor
    shell = systemu("netstat -an | grep tcp")
    if not shell.success? then
      error()
    end
    lines = shell.stdout.split("\n")

    ret = {}
    lines.each do |line|
      line = line.split(/\s+/)
      type = line[-1].downcase
      if ret[type] then
        ret[type] += 1
      else
        ret[type] = 1
      end
    end

    ret.each_pair do |type, count|
      add_metric({:state => count}, {:state => type})
    end

  end

end

Bixby::Monitoring::Base.subclasses.last.new.run if $0 == __FILE__
