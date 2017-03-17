#!/usr/bin/env ruby

require 'json'
require 'mongo'

require 'pry'

def usage
  $stderr.puts "Usage: #{File.basename __FILE__} JSON"
end

def error(type, exception)
  return "Attempted duplicate insertion of record with key #{exception[/"([^"]+)"/,1]}" if type == :duplicate_key
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

begin
  result = collection.insert_one(data)
rescue => exception
  $stderr.puts error(:duplicate_key, exception.message) if exception.message.include?('duplicate key error')
  exit 1
end

puts result.inserted_id
