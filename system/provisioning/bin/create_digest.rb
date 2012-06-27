#!/usr/bin/env ruby

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

path = File.expand_path(path)
sha = Digest::SHA2.new
bundle_sha = Digest::SHA2.new

digests = []
Dir.glob("#{path}/**/*").sort.each do |f|
  next if File.directory?(f) || File.basename(f) == "digest"
  bundle_sha.file(f)
  sha.reset()
  digests << { :file => f.gsub(/#{path}\//, ''), :digest => sha.file(f).hexdigest() }
end

digest = { :digest => bundle_sha.hexdigest(), :files => digests }
File.open(path+"/digest", 'w') do |f|
  f.write(JSON.pretty_generate(digest) + "\n")
end
