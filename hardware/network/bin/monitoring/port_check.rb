#!/usr/bin/env ruby

# Copyright (c) 2008-2013 Scout Monitoring
# Licensed under the MIT license
# See: https://github.com/scoutapp/scout-plugins

use_bundle "system/monitoring"

require 'socket'

class PortCheck < Bixby::Monitoring::Base

  def monitor
    port = option(:port) || ""
    port = port.strip if not port.nil?
    if port.strip.empty? then
      return error("Host/port not specified")
    end

    add_metric({:open => is_port_open?(port)}, {:port => port})
  end

  private

  def is_port_open?(host_and_port)
    host, port = host_and_port.split(":")
    begin
      s = TCPSocket.open(host, port.to_i)
      s.close
      return 1
    rescue Exception => ex
      error(ex.message)
      return 0
    end
  end
end


Bixby::Monitoring::Base.subclasses.last.new.run if $0 == __FILE__
