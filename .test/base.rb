
module Bixby
  class TestCase < MiniTest::Unit::TestCase

    class << self
      attr_accessor :bundle
    end

    def setup
      super
      FileUtils.mkdir_p File.join(BIXBY_HOME_PATH, "repo")
      FileUtils.ln_sf BIXBY_REPO_PATH, File.join(BIXBY_HOME_PATH, "repo", "vendor")
    end

    def teardown
      super
      FileUtils.rm_rf BIXBY_HOME_PATH
    end

    private

    def bundle
      self.class.bundle
    end

    def bin(*args)
      path_to(bundle, "bin", *args)
    end

    def path_to(*args)
      File.join(Bixby.repo_path, "vendor", *args)
    end

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

