#!/usr/bin/env ruby

require 'rubygems'
require 'facter'
require 'multi_json'

# ec2 userdata returns an array with one word per line for some reason, so just ignore it

exclude_keys = %w(swapfree memoryfree ec2_userdata)
facts = Facter.to_hash
exclude_keys.each { |k| facts.delete(k) }

puts MultiJson.dump(facts)
