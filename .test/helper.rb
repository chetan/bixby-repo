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
require 'simplecov'
SimpleCov.configure do
  coverage_dir '.coverage'
end
TestGuard.load_simplecov()

# Load any HTTP clients before webmock so they can be stubbed
require 'curb'
require 'webmock'
include WebMock::API
require 'mocha/setup'

# add .test path to $:
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require "bixby-common"
require "bixby-client/script"
require "base"

BIXBY_REPO_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))
BIXBY_HOME_PATH = "/tmp/bixby_repo_test"

s = File.join(BIXBY_HOME_PATH, "repo", "vendor")
if not File.symlink? s then
  FileUtils.mkdir_p File.join(BIXBY_HOME_PATH, "repo")
  FileUtils.ln_sf BIXBY_REPO_PATH, s
end

dir = File.join(BIXBY_REPO_PATH, "..")
ENV["BIXBY_HOME"] = BIXBY_HOME_PATH
ENV["BIXBY_REPO_PATH"] = BIXBY_REPO_PATH
ENV["RUBYLIB"] = "#{dir}/common/lib:#{dir}/client/lib:#{dir}/agent/lib"
ENV["RUBYOPT"] = '-rbixby-client/script'

MiniTest::Unit.autorun
