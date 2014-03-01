#!/usr/bin/env ruby

use_bundle "system/monitoring"

class EntropyAvail < Bixby::Monitoring::Base

  def monitor
    if linux? then
      add_metric(:count => File.read("/proc/sys/kernel/random/entropy_avail").strip.to_i)
    elsif darwin? then
      # TODO darwin is not supported
    end
  end

end

Bixby::Monitoring::Base.subclasses.last.new.run if $0 == __FILE__
