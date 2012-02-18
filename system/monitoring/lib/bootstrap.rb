
require 'rubygems'

gem 'devops_common'
gem 'devops_agent'

require 'devops_agent'
require File.dirname(__FILE__) + "/base"

def bootstrap(argv)
  # find script in ARGV (accounting for spaces)
  agent = Agent.create()
  script = argv.shift
  if script !~ %r{^/} then
    script = File.join(BundleRepository.path, script)
  end
  while not File.exists? script and not argv.empty? do
    script += " " + argv.shift
  end

  if not File.exists? script then
    raise CommandNotFound, script, caller
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
