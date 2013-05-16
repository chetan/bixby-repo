#!/usr/bin/env ruby

# dump all metric keys

require "multi_json"
require "terminal-table"

ROOT = File.expand_path(File.dirname(__FILE__))

scripts = []

jsons = Dir.glob(File.join(ROOT, "**/bin/monitoring/*.rb.json")).sort
jsons.each do |file|
  json = MultiJson.load(File.read(file))
  key = json["key"]
  json["metrics"].keys.each do |m|
    scripts << [ "#{key}.#{m}", json["metrics"][m]["desc"] ]
  end
end

puts Terminal::Table.new(:headings => %w{Metric Description}, :rows => scripts)
