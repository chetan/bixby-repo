#!/usr/bin/env ruby

class Provision < BundleCommand

    include HttpClient

    def initialize
        super
    end

    def run!

        begin
            cmd = CommandSpec.from_json(ARGV.join(" "))
        rescue Exception => ex
            puts "failed"
            exit
        end

        files = Provisioning.list_files(cmd)
        Provisioning.download_files(cmd, files)

    end

end

Provision.new.run!
