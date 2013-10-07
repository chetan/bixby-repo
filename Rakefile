# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'rake/tasklib'

require "easycov/rake"
require "micron/rake"
Micron::Rake.new do |task|
end
task :default => :test


desc "Report coverage to coveralls"
task :coveralls do
  require "easycov"
  require "coveralls"

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  cov_file = File.join(EasyCov.path, ".resultset.json")
  if File.exists? cov_file then
    data = MultiJson.load(File.read(cov_file))
    # We report on only the most recent coverage run
    if last_key = data.keys.last then
      SimpleCov::Result.from_hash(last_key => data[last_key]).format!
    end
  end
end
