#!/usr/bin/env ruby

require "digest"
require "fileutils"

module Bixby
  class Provision < Bixby::Command

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

      delete_files(cmd, files)
    end

    # Delete files which no longer exist in the bundle
    #
    # @param [CommandSpec] cmd    CommandSpec representing the Bundle to which the files belong
    # @param [Hash] files         List of files in bundle, as reported by Bixby::Repository#list_files
    def delete_files(cmd, files)
      bundle_files = files.map{ |pair| pair["file"] }

      all_files = Dir.glob(File.join(cmd.bundle_dir, "**")).reject{ |f| File.directory? f }
      all_files.each do |local_file|
        if not bundle_files.include? local_file then
          debug { "deleting obsolete file: #{local_file}" }
          File.delete(local_file)
        end
      end
    end

  end # Provision
end # Bixby

Bixby::Provision.new.run
