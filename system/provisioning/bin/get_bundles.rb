#!/usr/bin/env ruby

require "digest"
require "fileutils"

module Bixby
  class ProvisionBundles < Bixby::Command

    def run

      input = get_json_input()
      if input.nil? or input.empty? then
        $stderr.puts "missing file list"
        exit 1
      end

      input.each do |bundle, opts|
        cmd = Bixby::CommandSpec.new(:bundle => bundle, :repo => opts["repo"])
        download_files(cmd, opts["files"])
        delete_files(cmd, opts["files"])
        cmd.update_digest

        # log the updated digest
        spec = Bixby::CommandSpec.new(:bundle => cmd.bundle, :repo => cmd.repo)
        digest = spec.load_digest["digest"]
        logger.debug { "updated digest for bundle #{spec.repo}:#{spec.bundle} = #{digest}" }
      end

    end




    ###
    ### TODO - copied from get_bundle for now. fix!
    ###

    # Download the given list of files belonging to the given bundle
    #
    # @param [CommandSpec] cmd
    # @param [Array<Hash>] files
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
          logger.debug { "skipping: #{f}" }
          next
        end

        logger.debug { "fetching: #{f}"}

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
    # @param [Array<Hash>] files         List of files in bundle, as reported by Bixby::Repository#list_files
    def delete_files(cmd, files)
      logger.debug { "cleaning up stale files" }
      bundle_files = files.map{ |pair| pair["file"] }

      all_files = Dir.glob(File.join(cmd.bundle_dir, "**/**")).reject{ |f| File.directory? f }.map{ |f| f[cmd.bundle_dir.length+1, f.length] }
      all_files.each do |local_file|
        logger.debug { "found local file: #{local_file}" }
        if not bundle_files.include? local_file then
          next if local_file == "digest"
          file = File.join(cmd.bundle_dir, local_file)
          logger.debug { "deleting: #{file}" }
          File.delete(file)
        end
      end
    end

  end
end

Bixby::ProvisionBundles.new.run if $0 == __FILE__
