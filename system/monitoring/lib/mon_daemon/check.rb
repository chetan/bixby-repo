module Bixby
  module Monitoring

    class Check
      attr_accessor :clazz, :key, :options, :config, :interval, :retry, :timeout, :storage

      # Create a new instance of the Check described by this object
      def create
        self.clazz.new(self.options.dup, self.config.dup)
      end
    end

  end
end
