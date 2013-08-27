#!/usr/bin/env bash

if [[ $1 == "--beta" ]]; then
  BETA=1
fi

\curl -sL https://get.bixby.io | BETA=$BETA bash -s
