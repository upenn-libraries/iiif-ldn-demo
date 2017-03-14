#!/usr/bin/env ruby

require 'json'
require 'mongo'

def usage
  $stderr.puts "Usage: #{File.basename __FILE__} JSON"
end

path = ARGV.shift

unless path && File.exists?(path)
  $stderr.puts "I need a real file path; not '#{path}'"
  usage
  exit 1
end

data = JSON::load open(path).read

db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'iiif-notifications')

collection = db[:manifests]

result = collection.insert_one data

puts result.inserted_id
