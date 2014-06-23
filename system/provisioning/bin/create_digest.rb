#!/usr/bin/env ruby

require 'bundler/setup'
require 'bixby-common'
require 'digest'
require 'multi_json'
require 'oj'

path = ARGV.join(" ")
path = "." if path.nil? or path.empty?
if not File.exist? path then
  puts "path '#{path}' does not exist"
  exit 1
end

if not File.exist? "#{path}/manifest.json" then
  puts "path '#{path}/manifest.json' does not exist"
  exit 1
end

path.gsub!(%r{^\./}, '')

puts "updating bundle digest for #{path}"

ENV["BIXBY_HOME"] = Dir.pwd

# validate all json files
errors = false
Dir.glob(File.join(path, "**/*.json"), File::FNM_CASEFOLD).each do |f|
  begin
    MultiJson.load(File.read(f))
  rescue MultiJson::ParseError => ex
    warn "ERROR: invalid json file #{f}: #{ex.message}"
    errors = true
  end
end
if errors then
  warn "aborting digest update due to errors"
  exit 1
end

# update digest
spec = Bixby::CommandSpec.new(:bundle => path, :repo => "..") # .. hack to fix paths
spec.update_digest
