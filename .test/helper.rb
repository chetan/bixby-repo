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
if ENV["COVERAGE"] then
  TestGuard.load_simplecov() do
    coverage_dir '.coverage'
  end
end

require "minitest/parallel_each"
require "test_guard/minitest_fork"

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

MiniTest::Unit.autorun
