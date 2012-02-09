
require 'rubygems'

gem 'devops_common'
gem 'devops_agent'

require 'devops_agent'
require File.dirname(__FILE__) + "/base"

def bootstrap(argv)
  # find script in ARGV (accounting for spaces)
  script = argv.shift
  while not File.exists? script do
    script += " " + argv.shift
  end

  if not File.exists? script then
    return nil
  end

  # look for the bundle root dir and add lib/ to load path
  bundledir = File.directory?(script) ? script : File.dirname(script)
  while not File.exists? File.join(bundledir, "manifest.json")
    bundledir = File.dirname(bundledir)
  end
  $: << File.join(bundledir, "lib")
  begin; require File.basename(bundledir); rescue LoadError; end

  return [ bundledir, script ]
end