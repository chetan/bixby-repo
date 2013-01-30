#!/usr/bin/env ruby

require "digest"
require "fileutils"

module Bixby
  class Provision < Bixby::BundleCommand

    def run

      input = get_json_input()
      if input.nil? or input.empty? then
        $stderr.puts "missing CommandSpec"
        exit 1
      end

      begin
        digest = input.delete("digest")
        cmd = CommandSpec.new(input)
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace.join("\n")
        exit 1
      end

      # see if it exists and is up to date already
      begin
        if cmd.validate(digest) == true then
          # digest matches, already up to date
          debug { "bundle #{cmd.bundle} is already up to date" }
          return
        end
      rescue Exception => ex
        # expected if bundle/command doesn't exist or is out of date
        # (digest doesn't match)
        debug { "bundle #{cmd.bundle} will be updated: #{ex.inspect}" }
      end

      files = Bixby::Repository.list_files(cmd)
      Bixby::Repository.download_files(cmd, files)

    end

  end # Provision
end # Bixby

Bixby::Provision.new.run
