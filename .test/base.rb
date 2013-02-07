
require "./system/monitoring/lib/base"

module Bixby
  class TestCase < MiniTest::Unit::TestCase

    def setup
      super
    end

    def teardown
      super
    end

    private

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
      bundle.gsub!(/#{Bixby.repo_path}/, '')
      lib = File.join(Bixby.repo_path, bundle, "lib")
      $: << lib
      if File.directory? lib then
        Dir.glob(File.join(lib, "*.rb")).each{ |f| require f }
      end
    end

  end
end

