module Bixby
  module Monitoring

    class Check
      attr_accessor :bundle, :file, :clazz, :key,
                    :options, :config, :interval, :retry, :timeout, :storage

      # Create a new instance of the Check described by this object
      def create
        self.clazz.new(self.options.dup, self.config.dup)
      end

      def to_s
        sprintf("%s key=%s bundle=%s file=%s", clazz, key, bundle, file)
      end

    end

  end
end
