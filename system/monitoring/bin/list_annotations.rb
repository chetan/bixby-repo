#!/usr/bin/env ruby

# temp workaround
require "httpi"
HTTPI.log = false

module Bixby
  module Model
    class Annotation < Base

      def self.list(name=nil, detail=nil)
        url = "/annotations?"
        if name and !name.empty? then
          url += "&name=#{name}"
        end
        if detail and !detail.empty? then
          url += "&detail=" + ERB::Util.url_encode(detail)
        end
        get(url)
      end

    end
  end
end

annotations = Bixby::Model::Annotation.list(ARGV.shift, ARGV.shift)
json = annotations.map do |a|
  {
    :name       => a.name,
    :tags       => a.tags,
    :detail     => a.detail,
    :created_at => a.created_at
  }
end

puts MultiJson.dump(json)
