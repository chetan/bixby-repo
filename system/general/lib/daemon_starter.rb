
require "daemons"
require "fileutils"

module Daemons
  class Controller

    def catch_exceptions(&block)
      begin
        block.call
        @error = false
      rescue CmdException, OptionParser::ParseError => e
        @error = true
        puts "ERROR: #{e.to_s}"
        puts
        print_usage()
      rescue RuntimeException => e
        @error = true
        puts "ERROR: #{e.to_s}"
      end
    end

    def error?
      @error == true
    end

  end
end

module Bixby
  class DaemonStarter

    def initialize(dir, name)
      @filename = File.join(dir, name + ".starting")
    end

    # Check if the daemon should start
    def start?
      if not(ARGV.include? "start" or ARGV.include? "restart") then
        # some command other than start or restart
        return true
      end

      return false if File.exists? @filename

      FileUtils.touch(@filename)
      @file = File.new(@filename)
      if @file.flock(File::LOCK_EX|File::LOCK_NB) == false then
        return false
      end

      return true
    end

    def cleanup!
      begin
        @file.flock(File::LOCK_UN) # unlock
      rescue => ex
      end
      begin
        File.delete(@filename) if File.exists? @filename
      rescue => ex
      end
    end

  end
end
