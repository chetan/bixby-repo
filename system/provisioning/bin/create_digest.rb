#!/usr/bin/env ruby

require 'bundler/setup'
require 'bixby-common'
require 'digest'
require 'json'

path = ARGV.join(" ")
if not File.exist? path then
  puts "path '#{path}' does not exist"
  exit 1
end

if not File.exist? "#{path}/manifest.json" then
  puts "path '#{path}/manifest.json' does not exist"
  exit 1
end

path.gsub!(%r{^\./}, '')

ENV["BIXBY_HOME"] = Dir.pwd
spec = Bixby::CommandSpec.new(:bundle => path, :repo => "..")
spec.update_digest
