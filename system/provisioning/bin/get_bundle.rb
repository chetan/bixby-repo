#!/usr/bin/env ruby

require "digest"
require "fileutils"

module Bixby
  class Provision < Bixby::BundleCommand

    def run

      input = get_json_input()
      if input.nil? or input.empty? then
        puts "missing CommandSpec"
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

      files = list_files(cmd)
      download_files(cmd, files)

    end

    # Retrieve a file listing for the given Bundle
    #
    # @param [CommandSpec] cmd      CommandSpec representing the Bundle to list
    # @return [Hash]                Hash containing the bundle digest and file list
    def list_files(cmd)
      req = JsonRequest.new("provisioning:list_files", cmd.to_hash)
      res = @agent.exec_api(req)
      return res.data
    end

    # Download athe given list of files
    #
    # @param [CommandSpec] cmd    CommandSpec representing the Bundle to which the files belong
    # @param [Hash] files         Hash, returned from #list_files
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

        next if not fetch

        params = cmd.to_hash
        params.delete(:digest)

        filename = File.join(local_path, f['file'])
        path = File.dirname(filename)
        if not File.exist? path then
          FileUtils.mkdir_p(path)
        end

        req = JsonRequest.new("provisioning:fetch_file", [ params, f['file'] ])
        @agent.exec_api_download(req, filename)
        if f['file'] =~ /^bin/ then
          # correct permissions for executables
          FileUtils.chmod(0755, filename)
        end
      end # files.each

      cmd.update_digest
    end

end # Provision
end # Bixby

Bixby::Provision.new.run
