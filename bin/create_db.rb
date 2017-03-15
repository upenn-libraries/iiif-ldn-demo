#!/usr/bin/env ruby

require 'mongo'

db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'iiif-notifications')

manifests = db[:manifests]
manifests.indexes.create_one({ '@id': 1 }, unique: true )

notifications = db[:notifications]
notifications.indexes.create_one({ '@id': 1 }, unique: true)
