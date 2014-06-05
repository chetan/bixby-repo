#!/usr/bin/env ruby

name = ARGV.shift
if name.nil? or name.empty? then
  cmd = File.basename($0)
  puts "usage: #{cmd} name [tag1,tag2] [detail]"
  puts "       or"
  puts "       echo detail | #{cmd} name [tag1,tag2]"
  puts
  puts "timestamp will be set to the current time"
  exit 1
end

tags = ARGV.shift
detail = read_stdin() || ARGV.shift

req = Bixby::JsonRequest.new("metrics:add_annotation", [ name, tags, nil, detail ])
ret = Bixby.client.exec_api(req)
if ret.error? then
  STDERR.puts ret.to_s
  exit 1
end
