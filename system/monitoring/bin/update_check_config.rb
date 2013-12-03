#!/usr/bin/env ruby

# Uninstall god service
def uninstall_service
  god_file = Bixby.path("etc", "god.d", "bixby-monitoring.god")
  # bail if no init script or not setup
  return if not File.exists? "/etc/init.d/bixby" or not File.exists? god_file
  File.delete(god_file)
  systemu("/etc/init.d/bixby reload")
end

# Install god service
#
# @return [Fixnum] 0 if not avail, 1 if already installed, 2 if newly installed
def install_service
  god_file = Bixby.path("etc", "god.d", "bixby-monitoring.god")

  # bail if no init script or already setup
  return 0 if not File.exists? "/etc/init.d/bixby"
  return 1 if File.exists? god_file

  begin
    require "bixby-agent/version"
    require "semver"
  rescue LoadError => ex
    return 0 # no god support before 0.2
  end

  use_bundle "system/general"
  use_bundle "system/monitoring"

  if SemVer.parse("v"+Bixby::Agent::VERSION) < SemVer.parse("v0.2.0") then
    return 0 # no god support before 0.2
  end

  # copy god config
  require "fileutils"
  local = File.join(File.expand_path("../../etc/bixby-monitoring.god", __FILE__))
  FileUtils.cp(local, god_file)
  File.chmod(0644, god_file)

  return 2
end

require "bixby-client/script"

path = Bixby.path("etc", "monitoring")
FileUtils.mkdir_p(path)

# copy stdin to config file
config_file = File.join(path, "config.json")
config = read_stdin()
File.open(config_file, 'w') { |f| f.write(config) }

# make sure service is setup
begin
  c = MultiJson.load(config)
rescue Exception => ex
end
if c.nil? or c.empty? then
  uninstall_service()
  exit 0
end

case install_service()
when 0
  logger.debug "restarting mon_daemon.rb"
  rpath = File.dirname(File.expand_path(__FILE__))
  shell = systemu("#{rpath}/mon_daemon.rb restart")
  logger.debug { Bixby::CommandResponse.new(shell).to_s }

when 1
  logger.debug "restarting bixby-monitoring-daemon"
  systemu("/etc/init.d/bixby god restart monitoring")

when 2
  # stop old service
  logger.debug "killing old mon_daemon service"
  rpath = File.dirname(File.expand_path(__FILE__))
  systemu("#{rpath}/mon_daemon.rb stop")
  systemu("sudo pkill -9 -f mon_daemon.rb") # make sure old service is dead

  # restart god service to get new config
  logger.debug "reloading bixby-god"
  systemu("/etc/init.d/bixby reload")

end
