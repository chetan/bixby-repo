#!/usr/bin/env ruby

# Copyright (c) 2008-2013 Scout Monitoring
# Licensed under the MIT license
# See: https://github.com/scoutapp/scout-plugins

use_bundle "system/monitoring"

# Takes an IP or hostname. Reports 1 if it can ping the host, 0 if it can't
class Ping < Scout::Plugin

  def build_report
    host = option('host')
    error("You must provide an IP or host to ping") and return if !host

    ping = `ping -c1 #{host} 2>&1`
    res = ping.include?("bytes from") ? 1 : 0
    report(:status=>res)

  end
end


Scout::Plugin.subclasses.first.new.run if $0 == __FILE__
