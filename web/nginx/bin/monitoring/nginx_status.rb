#!/usr/bin/env ruby

use_bundle "web/nginx"
use_bundle "system/monitoring"

module Bixby
module Web
  class NginxMon < Monitoring::Base

    include Bixby::Web::Nginx::Status

    def monitor
      stats = read_status(@options["url"])

      # load previous stats and store current
      prev_stats = recall(:stats)
      store(:stats => stats.to_hash)

      metrics = {
        :active_conns => stats.active_conns,
        :reading      => stats.reading,
        :writing      => stats.writing,
        :waiting      => stats.waiting
      }

      if prev_stats && !prev_stats.empty? then
        # add diffs for conn & request rates
        metrics[:accepted_conns] = stats.accepted_conns - prev_stats[:accepted_conns]
        metrics[:handled_conns]  = stats.handled_conns - prev_stats[:handled_conns]
        metrics[:requests]       = stats.requests - prev_stats[:requests]
      end

      add_metrics(metrics)
    end

  end
end
end

Bixby::Web::NginxMon.new.run if $0 == __FILE__
