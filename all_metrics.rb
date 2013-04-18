#!/usr/bin/env ruby

# dump all metric keys

require "multi_json"

ROOT = File.expand_path(File.dirname(__FILE__))

jsons = Dir.glob(File.join(ROOT, "**/bin/monitoring/*.rb.json")).sort
jsons.each do |file|
  json = MultiJson.load(File.read(file))
  key = json["key"]
  json["metrics"].keys.each do |m|
    puts "#{key}.#{m}"
  end
end



