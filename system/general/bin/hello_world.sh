#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo hello world
else
  echo hello $@
fi
