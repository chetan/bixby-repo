
module Monitoring

  class UpdateCheckConfig < BundleCommand

    def run
      path = "#{DEVOPS_ROOT}/etc/monitoring/"
      systemu("mkdir -p #{path}")
      config_file = "#{path}/config.json"

      File.open(config_file, 'w') { |f| f.write(read_stdin()) }

      # restart mond.rb
      rpath = File.dirname(File.expand_path(__FILE__))
      mond = "#{rpath}/ruby_wrapper.rb #{rpath}/mon_daemon.rb -- "

      status, stdout, stderr = systemu("#{mond} restart")

      # for now we'll always restart to avoid code replacement
      # on check version updates. may reload in future..

      # status, stdout, stderr = systemu("#{mond} status")
      # if stdout =~ /no instances running/ then
      #   status, stdout, stderr = systemu("#{mond} start")
      # else
      #   status, stdout, stderr = systemu("#{mond} reload")
      # end
    end

  end

end
