#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__)) + "/../lib/bootstrap"
require 'mixlib/cli'

class RubyWrapper

  include Mixlib::CLI

  option :monitor,
      :short          => "-m",
      :long           => "--monitor",
      :description    => "Retrieve metrics",
      :boolean        => true

  option :options,
      :short          => "-o",
      :long           => "--options",
      :description    => "List options used by plugin",
      :boolean        => true

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
      (@bundle_dir, @script) = bootstrap(@argv)
    rescue CommandNotFound => ex
      puts "CommandNotFound: #{ex.message}"
      exit 1
    end

    @cmd = if @config[:monitor] then
      "monitor"
    elsif @config[:options] then
      "options"
    elsif @config[:test] then
      "test"
    else
      puts "missing command"
      exit 1
    end
  end

  def run
    if @cmd == "test" then
      return run_test()
    end

    return run_bin()
  end

  def run_bin
    if not File.file? @script then
      puts "error: need a script to run!"
      exit 2
    end

    require @script
    config = (File.exists?("#{@script}.json") ? JSON.parse(File.read("#{@script}.json")) : nil)
    input = read_stdin()
    options = (input.nil? or input.empty?) ? {} : JSON.parse(input)

    # TODO make sure only 1 is returned??
    Monitoring::Base.subclasses.first.new(@cmd, options, config).run
  end

  def run_test
    require File.expand_path(File.dirname(__FILE__)) + "/../lib/bootstrap_test"
    if File.file? @script and @script =~ %r{#{@bundle_dir}/test} then
      require @script
      return
    end

    Dir.glob("#{@bundle_dir}/test/**/test_*.rb").each do |f|
      require f
    end
  end

  def read_stdin
    buff = []
    while true do
      begin
        buff << STDIN.read_nonblock(64000)
      rescue => ex
        break
      end
    end
    return buff.join('')
  end

end # class RubyWrapper

RubyWrapper.new.run
