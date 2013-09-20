require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test_guard'
require "simplecov"
require "easycov"
require "micron"
require "micron/minitest"

# Load any HTTP clients before webmock so they can be stubbed
require 'curb'
require 'webmock'
include WebMock::API
require 'mocha/setup'

# add .test path to $:
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

# TODO temp fix for log path in Bixby::Log.setup_logger()
ENV["BIXBY_HOME"] = "/tmp/bixby_repo_test"
system("mkdir -p /tmp/bixby_repo_test")

require "bixby-common"
require "bixby-client/script"
require "base"

BIXBY_REPO_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))

dir = File.join(BIXBY_REPO_PATH, "..")
ENV["BIXBY_REPO_PATH"] = BIXBY_REPO_PATH
ENV["RUBYLIB"] = "#{dir}/common/lib:#{dir}/client/lib:#{dir}/agent/lib"
ENV["RUBYOPT"] = '-rbixby-client/script'

EasyCov.path = ".coverage"
EasyCov.filters << EasyCov::IGNORE_GEMS << EasyCov::IGNORE_STDLIB
EasyCov.filters << lambda { |f| f =~ %r{^#{EasyCov.root}/.test} }

# EasyCov.install_exit_hook
EasyCov.start
