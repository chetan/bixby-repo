#!/usr/bin/env ruby

# Run facter and return all facts as a JSON hash

require 'rubygems'
require 'facter'
require 'multi_json'

# ec2 userdata returns an array with one word per line for some reason, so just ignore it

exclude_keys = %w(swapfree memoryfree ec2_userdata)
facts = Facter.to_hash.reject{ |k,v| exclude_keys.include?(k) || k =~ /ssh.*key|sshfp_.*/ }
puts MultiJson.dump(facts)
