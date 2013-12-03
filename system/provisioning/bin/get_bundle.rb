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


      download_bundle(cmd)
    end

    # Download the given bundle
    #
    # @param [CommandSpec] cmd
    def download_bundle(cmd)
      files = Bixby::Repository.list_files(cmd)
      download_files(cmd, files)
      delete_files(cmd, files)

      cmd.update_digest
    end

    # Download the given list of files belonging to the given bundle
    #
    # @param [CommandSpec] cmd
    # @param [Hash] files
    def download_files(cmd, files)
      return if files.nil? or files.empty?

      local_path = cmd.bundle_dir
      digest = cmd.load_digest
      files.each do |f|

        fetch = true
        if not digest then
          fetch = true
        elsif df = digest["files"].find{ |h| h["file"] == f["file"] } then
          # compare digest w/ stored one if we have it
          fetch = (df["digest"] != f["digest"])
        else
          fetch = true
        end

        if not fetch then
          debug { "skipping: #{f}" }
          next
        end

        debug { "fetching: #{f}"}

        filename = File.join(local_path, f['file'])
        path = File.dirname(filename)
        if not File.exist? path then
          FileUtils.mkdir_p(path)
        end

        Bixby::Repository.fetch_file(cmd, f['file'], filename)
        if f['file'] =~ /^bin/ then
          # correct permissions for executables
          FileUtils.chmod(0755, filename)
        end
      end # files.each
    end

    # Delete files which no longer exist in the bundle
    #
    # @param [CommandSpec] cmd    CommandSpec representing the Bundle to which the files belong
    # @param [Hash] files         List of files in bundle, as reported by Bixby::Repository#list_files
    def delete_files(cmd, files)
      bundle_files = files.map{ |pair| pair["file"] }

      all_files = Dir.glob(File.join(cmd.bundle_dir, "**")).reject{ |f| File.directory? f }.map{ |f| f[cmd.bundle_dir.length+1, f.length] }
      all_files.each do |local_file|
        if not bundle_files.include? local_file then
          next if local_file == "digest"
          file = File.join(cmd.bundle_dir, local_file)
          debug { "deleting: #{file}" }
          File.delete(file)
        end
      end
    end

  end # Provision
end # Bixby

Bixby::Provision.new.run if $0 == __FILE__
