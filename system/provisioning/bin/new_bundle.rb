#!/usr/bin/env ruby

name = ARGV.shift
if name.nil? or name.empty? then
  puts "error: bundle name not given"
  puts "usage: bixby run new_bundle <name>"
  puts "       creates a new bundle skeleton in the current directory"
  exit 1
end

path = File.expand_path(name)
FileUtils.mkdir_p(path)
FileUtils.mkdir_p(File.join(path, "bin"))
FileUtils.mkdir_p(File.join(path, "lib"))
FileUtils.mkdir_p(File.join(path, "test"))

shortname = File.basename(path)

File.open(File.join(path, "manifest.json"), "w") do |f|
  f.puts <<-EOF
{
  "name":        "#{shortname}",
  "version":     "0.1.0",
  "description": "#{shortname}"
}
EOF
end

puts "Created new bundle #{name}. Edit the manifest at #{name}/manifest.json"
puts "When finished, remember to update the digest file with "
puts "  > bixby run create_digest #{name}"
