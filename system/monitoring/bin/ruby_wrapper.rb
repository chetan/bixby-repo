#!/usr/bin/env ruby

require File.dirname(File.realpath(__FILE__)) + "/../lib/bootstrap"
require 'mixlib/cli'

module Bixby
class RubyWrapper

  include Mixlib::CLI

  option :test,
      :short          => "-t",
      :long           => "--test",
      :description    => "Run test(s) for given bundle",
      :boolean        => true

  option :help,
      :short          => "-h",
      :long           => "--help",
      :description    => "Print this help",
      :boolean        => true,
      :show_options   => true,
      :exit           => 0

  banner "Usage: #{$0} <cmd> file"

  def initialize
    super
    @argv = parse_options()
    ARGV.clear

    begin
      (@bundle_dir, @script) = Bixby.bootstrap(@argv)
    rescue CommandNotFound => ex
      puts "CommandNotFound: #{ex.message}"
      exit 1
    end
  end

  def run
    if @config[:test] then
      return run_test()
    end

    return run_bin()
  end

  def run_bin
    if not File.file? @script then
      puts "error: need a script to run!"
      exit 2
    end

    @argv.each{ |a| ARGV << a }
    require @script

    options = nil
    if File.exists? "#{@script}.json" then
      options = MultiJson.load(File.read("#{@script}.json"))
    end

    # TODO make sure only 1 is returned??
    BundleCommand.subclasses.last.new(options).run
  end

  def run_test
    require File.dirname(File.realpath(__FILE__)) + "/../lib/bootstrap_test"
    if File.file? @script and @script =~ %r{#{@bundle_dir}/test} then
      require @script
      return
    end

    Dir.glob("#{@bundle_dir}/test/**/test_*.rb").each do |f|
      require f
    end
  end

end # RubyWrapper
end # Bixby

Bixby::RubyWrapper.new.run
