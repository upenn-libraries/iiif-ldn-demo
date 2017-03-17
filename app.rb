
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

# Connect to mongo; set the collections
configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'iiif-notifications')
  set :mongo_db, db
  set :manifests, db[:manifests]
  set :notifications, db[:notifications]
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

get '/' do
  content_type :json

  JSON.dump({})
end

# Return the manifest with `:name`
#
# GET '/iiif/:name/manifests'
get '/iiif/:name/manifest/?' do
  content_type :json
  headers 'Link' => '</notifications>; rel="http://www.w3.org/ns/ldp#inbox"'

  at_id = "http://library.upenn.edu/iiif/#{params[:name]}/manifest"
  manifest = settings.manifests.find({'@id': at_id}).to_a.first
  manifest.delete "_id" unless manifest.nil?
  JSON.pretty_generate manifest || {}
end

# Accept a notification
# POST '/iiif/notifications'
post '/iiif/notifications' do
  return 415 unless request.content_type == 'application/json'

  content_type :json

  begin
    payload = JSON.parse(request.body.read)
    result = settings.notifications.insert_one payload

    JSON.pretty_generate result.inserted_id
  rescue Mongo::Error::OperationFailure => e
    return 500
  end
end

# GET '/iiif/notifications' # return all notfifications
# GET '/iiif/notifications?target=<URL>'
get '/iiif/notifications/?' do
  content_type :json

  protocol  = request.ssl? ? 'https': 'http'
  host_port = request.host_with_port
  path      = request.path

  this_uri  = "#{protocol}://#{host_port}#{path}"

  # Theres a target, find all notifications on it
  args = params[:target].nil? ? nil : {target: params[:target]}
  # this_uri = request.env['REQUEST_URI']
  data = { '@context': 'http://www.w3.org/ns/ldp' }
  data[:'@id'] = this_uri
  data[:contains] = settings.notifications.find(args).map { |doc|
    # what_i_want = this_uri.sub /\?.*$/, ''
    # "#{doc['_id']}"
    "#{this_uri}/#{doc['_id']}"
  }
  JSON.pretty_generate data || {}
end

# Return a specific notification
#
# GET '/iiif/notifications/:id'
get '/iiif/notifications/:id' do
  content_type :json

  doc = document_by_id :notifications, params[:id]
  doc.delete :_id

  JSON.pretty_generate doc
end
