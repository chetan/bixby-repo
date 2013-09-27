#!/usr/bin/env ruby

require "bixby-agent/version"
require "semver"

use_bundle "system/general"
use_bundle "system/monitoring"

if SemVer.parse("v"+Bixby::Agent::VERSION) < SemVer.parse("v0.2.0") then
  # no god support before 0.2
  exit
end

god_file = Bixby.path("etc", "god.d", "bixby-monitoring.god")
if File.exists? god_file then
  # no need to do anything more
  exit
end

# copy god config
require "file_utils"
local = File.join(File.expand_path("../../etc/bixby-monitoring.god", __FILE__))
FileUtils.cp(local, god_file)

# restart god
system("/etc/init.d/bixby reload")
