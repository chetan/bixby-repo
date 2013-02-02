
cd $(dirname $(readlink -f $0))
find . -mindepth 2 -maxdepth 2 -type d  | egrep -v ^\\./\\. | xargs -n 1 ./system/provisioning/bin/create_digest.rb

