#!/usr/bin/env bash

if [[ $1 == "--beta" ]]; then
  BETA=1
fi

[[ -f /etc/init.d/bixby ]]
HAS_INIT=$?

\curl -sL https://get.bixby.io | BETA=$BETA bash -s

function is_registered {
  [[ -f /opt/bixby/etc/bixby.yml && -f /opt/bixby/etc/server.pub ]]
}

function do_restart {
  if is_registered; then
    sleep 3 # short nap, then bounce away

    if [[ $HAS_INIT -eq 0 ]]; then
      # has init already, just restart
      /etc/init.d/bixby restart
    else
      # no init script previously
      /opt/bixby/bin/bixby-agent stop
      /etc/init.d/bixby start
    fi
  fi
}

# do restart in the background so we can return a proper response to the
# manager first
restart_bixby &
