find $(dirname $(readlink -f $0)) -mindepth 2 -maxdepth 2 -type d  | grep -v ./.git | xargs -n 1 ./system/provisioning/bin/create_digest.rb
