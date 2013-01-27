
BIXBY_HOME = ENV["BIXBY_HOME"]

require 'bixby-common'
require 'bixby-agent'
require File.join(File.dirname(__FILE__), "base")

Bixby.repo_path = File.join(BIXBY_HOME, "repo")

module Bixby

  # Bootstrap the Bixby command environment
  # * identify command in ARGV
  # * locate the correct bundle
  # * load bundle library
  # * setup ENV
  #
  # @param [Array<String>] argv   script arguments
  def self.bootstrap(argv)
    # find script in ARGV (accounting for spaces)
    script = argv.shift
    if not File.exist? script and script !~ %r{^/} then
      script = File.join(Bixby.repo_path, script)
    end
    while not File.exists? script and not argv.empty? do
      script += " " + argv.shift
    end

    if not File.exists? script then
      raise CommandNotFound, script, caller
    end

    script = File.expand_path(script)

    # look for the bundle root dir and add lib/ to load path
    bundledir = File.directory?(script) ? script : File.dirname(script)
    while not File.exists? File.join(bundledir, "manifest.json")
      bundledir = File.dirname(bundledir)
    end
    $: << File.join(bundledir, "lib")
    begin; require File.basename(bundledir); rescue LoadError; end

    bundledir = File.expand_path(bundledir)

    # export some vars into ENV
    b = bundledir.gsub(/^#{Bixby.repo_path}\//, '').split(%r{/})
    repo = b.shift
    bundle = b.join("/")
    command = File.file?(script) ? File.basename(script) : nil
    ENV["BIXBY_COMMAND_SPEC"] = CommandSpec.new(:repo => repo, :bundle => bundle, :command => command).to_json
    ENV["BIXBY_BUNDLE_DIR"] = bundledir

    return [ bundledir, script ]
  end

end # Bixby
