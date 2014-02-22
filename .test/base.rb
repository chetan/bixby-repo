
module Bixby
  class TestCase < Micron::TestCase

    class << self
      attr_accessor :bundle
    end

    def setup
      super

      # Create a temp BIXBY_HOME environment
      @bixby_home = Dir.mktmpdir("bixby-")
      ENV["BIXBY_HOME"] = @bixby_home
      s = File.join(@bixby_home, "repo", "vendor")
      if not File.exists? s then
        FileUtils.mkdir_p File.join(@bixby_home, "repo")
        FileUtils.ln_sf ENV["BIXBY_REPO_PATH"], File.join(@bixby_home, "repo", "vendor")

        # copy etc folder
        template = File.expand_path(File.join(File.dirname(__FILE__), "support", "root_dir"))
        `cp -a #{template}/* #{Bixby.root}/`
      end

      @test_bundle_path = File.expand_path(File.join(File.dirname(__FILE__), "support", "test_bundle"))
    end

    def teardown
      super
      FileUtils.rm_rf @bixby_home # Remove temp BIXBY_HOME env
    end


    private

    # Alias to bundle accessor
    def bundle
      self.class.bundle
    end

    # Retrieve the path to the given bin script
    #
    # @param [Array<String>] args
    #
    # @return [String] path to file
    #
    # @example
    #   bin("foo.rb") # returns "/opt/bixby/repo/vendor/my/bundle/bin/foo.rb"
    #
    def bin(*args)
      path_to(bundle, "bin", *args)
    end

    # Retrieve the path to the given relative path within the bundle
    #
    # @param [Array<String>] args
    #
    # @return [String] path to file
    def path_to(*args)
      File.join(Bixby.repo_path, "vendor", *args)
    end

    def debug?
      ENV["DEBUG"]
    end

    def dump(str)
      begin
        if str[0] == "{" then
          h = MultiJson.load(str)
          ap h
          if h["errors"] then
            h["errors"].each{ |e| puts e }
          end
          puts "---"
          return
        end
      rescue Exception => ex
      end

      puts str
      puts "---"
    end

    # Run command and log output before returning
    def systemu(*args)
      # Cleanup the ENV and execute
      old_env = {}
      %W{BUNDLE_BIN_PATH BUNDLE_GEMFILE}.each{ |r|
        old_env[r] = ENV.delete(r) if ENV.include?(r) }

      cmd = Mixlib::ShellOut.new(*args)
      cmd.run_command

      old_env.each{ |k,v| ENV[k] = v } # reset the ENV

      # return if not debug?
      puts "status: #{cmd.exitstatus}"
      puts "stdout:"
      dump cmd.stdout
      puts "stderr:"
      dump cmd.stderr
      cmd
    end

    # Set the @bundle var
    def self.inherited(subclass)
      super
      # figure out where we are getting included and then use that to find
      # the name of the bundle we're in. then load all libs in that bundle.
      #
      # e.g., caller.first = "/bixby/repo/hardware/cpu/test/test_cpu.rb:4:in `<top (required)>'"
      #       becomes "/hardware/cpu"
      #
      caller.first =~ %r{^(.*?)/test/.*\.rb:}
      bundle = $1
      bundle.gsub!(/#{BIXBY_REPO_PATH}\/?/, '')
      subclass.bundle = bundle
      lib = File.join(BIXBY_REPO_PATH, bundle, "lib")
      $: << lib
      if File.directory? lib then
        Dir.glob(File.join(lib, "*.rb")).each{ |f| require f }
      end
    end

  end
end

