
require 'sinatra'
require 'json'
require 'mongo'

require 'sinatra/reloader' if development?
require 'pry' if development?


directories = %w(lib)

directories.each do |directory|
  Dir["#{File.dirname(__FILE__)}/#{directory}/*.rb"].each do |file|
    require file
  end
end

helpers do
  # a helper method to turn a string ID
  # representation into a BSON::ObjectId
  def object_id val
    begin
      BSON::ObjectId.from_string(val)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end

  def document_by_id collection, id
    id = object_id(id) if String === id
    if id.nil?
      {}
    else
      document = settings.mongo_db[collection].find(:_id => id).to_a.first
      document || {}
    end
  end
end

configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'iiif-notifications')
  set :mongo_db, db
end

get '/' do
  'Hello, world!'
end

get '/iiif/:name/manifest/?' do
  content_type :json
  headers 'Link' => '</notifications>; rel="http://www.w3.org/ns/ldp#inbox"'

  at_id = "http://library.upenn.edu/iiif/#{params[:name]}/manifest"

  manifest = settings.mongo_db[:manifests].find({'@id': at_id}).to_a.first

  manifest.delete "_id" unless manifest.nil?
  JSON.pretty_generate manifest || {}
end

post '/iiif/notifications' do
  content_type :json

  begin
    payload = JSON.parse(request.body.read)

    result = settings.mongo_db[:notifications].insert_one payload

    content_type :json
    JSON.pretty_generate result.inserted_id
  rescue Mongo::Error::OperationFailure => e
    return 500
  end
end

get '/iiif/notifications/?' do
  content_type :json

  this_uri = request.env['REQUEST_URI']

  if params[:target]
    data = settings.mongo_db[:notifications].find(target: params[:target]).to_a.first
    data.delete :_id unless data.nil?
  else
    data = { '@context': 'http://www.w3.org/ns/ldp' }
    data[:'@id'] = this_uri
    data[:contains] = settings.mongo_db[:notifications].find().map { |doc|
      "#{this_uri}/#{doc['_id']}"
    }
  end
  JSON.pretty_generate data || {}
end

get '/iiif/notifications/:id' do
  content_type :json

  doc = document_by_id :notifications, params[:id]
  doc.delete :_id

  JSON.pretty_generate doc
end
