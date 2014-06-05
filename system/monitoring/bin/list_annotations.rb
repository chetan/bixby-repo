#!/usr/bin/env ruby

HTTPI.log = false # temp workaround

module Bixby
  module Model
    class Annotation < Base

      def self.list(name=nil)
        url = "/annotations"
        if name and !name.empty? then
          url += "?name=#{name}"
        end
        get(url)
      end

    end
  end
end

annotations = Bixby::Model::Annotation.list(ARGV.shift)
json = annotations.map do |a|
  {
    :name       => a.name,
    :tags       => a.tags,
    :detail     => a.detail,
    :created_at => a.created_at
  }
end

puts MultiJson.dump(json)
