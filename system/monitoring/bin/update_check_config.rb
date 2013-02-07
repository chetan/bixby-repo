#!/usr/bin/env ruby

require "bixby-client/script"

path = Bixby.path("etc", "monitoring")
FileUtils.mkdir_p(path)

# copy stdin to config file
config_file = File.join(path, "config.json")
File.open(config_file, 'w') { |f| f.write(read_stdin()) }

# restart mon_daemon.rb
#
# for now we'll always restart to avoid code replacement
# on check version updates. may reload in future..
rpath = File.dirname(File.expand_path(__FILE__))
status, stdout, stderr = systemu("#{rpath}/mon_daemon.rb restart")

debug {
  Bixby::CommandResponse.new({ :status => status.exitstatus,
                               :stdout => stdout,
                               :stderr => stderr }).to_s
}
