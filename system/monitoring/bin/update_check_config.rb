
require 'bixby-client'

module Bixby
module Monitoring

  class UpdateCheckConfig < Bixby::Command

    def run
      path = File.join(ENV["BIXBY_HOME"], "etc", "monitoring")
      systemu("mkdir -p #{path}")
      config_file = File.join(path, "config.json")

      File.open(config_file, 'w') { |f| f.write(read_stdin()) }

      # restart mon_daemon.rb
      #
      # for now we'll always restart to avoid code replacement
      # on check version updates. may reload in future..
      rpath = File.dirname(File.expand_path(__FILE__))
      systemu("#{rpath}/mon_daemon.rb --  restart")
    end

  end

end # Monitoring
end # Bixby
