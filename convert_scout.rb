#!/usr/bin/env ruby -wKU

require "yaml"
require "multi_json"
require "fileutils"
require "awesome_print"

ROOT = File.expand_path(File.dirname(__FILE__))

# cleanup a yaml string
def cleanup_yaml(str)
  str.gsub(/^(\s*?.*?:)(.*?)?$/) do |txt|
    key, val = $1, $2.strip
    if val.empty? then
      key
    else
      val = '"' + val + '"' if not val[0] == '"'
      "#{key} #{val}"
    end
  end
end

path = ARGV.shift
bundle = ARGV.shift

if path.nil? or bundle.nil? then
  puts "usage: #{$0} <path to scout plugin> <bundle name>"
  exit 1
end

puts "converting plugin: " + File.basename(path)
puts

path = File.dirname(File.expand_path(path)) if File.file? path
files = Dir.glob(File.join(path, "*.rb")).reject{ |f| f =~ /test.rb/ }
if files.size > 1 then
  puts "oops, found more than one file:"
  puts files
  puts
  puts "bailing.."
  exit 1
end

target_dir = File.join(ROOT, bundle, "bin", "monitoring")
FileUtils.mkdir_p(target_dir)

# write code
file = files.shift
code = <<-EOF
#!/usr/bin/env ruby

# Copyright (c) 2008-2013 Scout Monitoring
# Licensed under the MIT license
# See: https://github.com/scoutapp/scout-plugins

use_bundle "system/monitoring"

#{File.read(file)}

Scout::Plugin.subclasses.first.new.run if $0 == __FILE__
EOF

target = File.join(target_dir, File.basename(file))
File.open(target, "w"){ |f| f.write(code) }
File.chmod(0755, target)
puts "copied #{File.basename(file)} to #{bundle}"


# write config
config = file.gsub(/rb$/, "yml")
exit if not File.exist? config

target_config = target + ".json"
conf = YAML.load(cleanup_yaml(File.read(config)))
new_conf = File.exist?(target_config) ? MultiJson.load(File.read(target_config)) : {}

if not new_conf.include? "name" then
  new_conf["name"] = File.basename(target).gsub(/_/, ' ').gsub(/.rb$/, '')
  new_conf["key"] = ""
end

new_conf["metrics"] ||= {}

conf["metadata"].each do |key, info|
  metric = new_conf["metrics"][key] || {}
  metric["desc"] = info["label"]
  metric["unit"] = info["units"]

  new_conf["metrics"][key] = metric
end

new_conf["options"] ||= {}

if File.read(target) =~ /OPTIONS ?= ?<<-?([A-Z_]+)(.*)\1/m then
  options = YAML.load(cleanup_yaml($2))
  options.each do |opt, info|
    option = new_conf["options"][opt] || {}
    option["name"]    = info["name"] || opt.capitalize
    option["desc"]    = info["notes"]
    option["default"] = info["default"]
    option["type"]    = "text"

    new_conf["options"][opt] = option
  end
end

# ap conf
# ap new_conf

File.open(target_config, "w"){ |f| f.write(MultiJson.dump(new_conf, :pretty => true)) }

puts "copied #{File.basename(config)} to #{bundle}"
