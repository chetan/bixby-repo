#!/usr/bin/env ruby

require 'rubygems'
require 'facter'
require 'multi_json'

exclude_keys = %w(sshdsakey sshrsakey swapfree memoryfree)
facts = Facter.to_hash
exclude_keys.each { |k| facts.delete(k) }

puts MultiJson.dump(facts)
