#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__)) + "/../lib/bootstrap"
require 'mixlib/cli'

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

  def initialize
    super
    @argv = parse_options()
    (@bundle_dir, @script) = bootstrap(@argv)
    ARGV.clear
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
    require @script
  end

  def run_test
    require File.expand_path(File.dirname(__FILE__)) + "/../lib/bootstrap_test"
    if File.file? @script then
      require @script
      return
    end

    Dir.glob("#{@bundle_dir}/test/**/test_*.rb").each do |f|
      require f
    end
  end

end # class RubyWrapper

RubyWrapper.new.run
