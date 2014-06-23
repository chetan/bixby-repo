#!/bin/bash

# helper script for updating bundle digests
# considers every directory which contains 'manifest.json' to be a unique bundle

cd $(dirname $(readlink -f $0))
for f in `find . -type f -name 'manifest.json' | egrep -v '^\./\.'`; do
  d=$(dirname $f);
  ./system/provisioning/bin/create_digest.rb $d
done
