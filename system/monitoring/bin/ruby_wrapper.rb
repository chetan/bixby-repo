#!/usr/bin/env ruby

# usage
if ARGV.empty? then
  puts "usage: #{$0} <script>"
  exit
end

require 'rubygems'

gem 'devops_common'
gem 'devops_agent'

require 'devops_agent'

# find script in ARGV (accounting for spaces)
script = ARGV.shift
while not File.exists? script do
  script += " " + ARGV.shift
end

# look for the bundle root dir and add lib/ to load path
bundledir = File.dirname(script)
while not File.exists? File.join(bundledir, "manifest.json")
  bundledir = File.dirname(bundledir)
end
$: << File.join(bundledir, "lib")
begin; require File.basename(bundledir); rescue LoadError; end

# add helper(s)
begin; require 'awesome_print'; rescue LoadError; end
begin; require 'turn'; rescue LoadError; end

gem 'minitest'
require 'minitest/unit'

class MiniTest::Unit::TestCase
end

MiniTest::Unit.autorun

# run the script!
require script
