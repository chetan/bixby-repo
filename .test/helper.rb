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

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
ENV["RUBYLIB"] = $:.first

# put all lib folders on path
# Dir.glob(File.dirname(__FILE__) + "/../**/lib").each{ |f|
#   $: << f
# }

ENV["BIXBY_HOME"] = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

require "bixby-common"
require "bixby-client/script"
require "base"
# require "./system/monitoring/lib/base"

# Dir.glob(File.dirname(__FILE__) + "/../**/*.rb").each{ |f|
#   next if File.basename(f) =~ /^test_/
#   require f
# }
MiniTest::Unit.autorun
