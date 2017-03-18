
require 'sinatra'
require 'json'
require 'mongo'
require 'open-uri'

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

  def add_to_payload(doc, uri, type)
    args = params[:target].nil? ? nil : {target: params[:target]}
    data = settings.notifications.find(args).map { |doc|
      pull_payload_attributes(doc['object'], type)
    }
    return label_for_payload(type), data
  end

  def pull_payload_attributes(uri, type)
    response = JSON.parse(open(uri).read)
    return fetch_payload(response, type)
  end

  def fetch_payload(response, type)
    case type
      when 'sc:Range'
        return response['ranges']
      else
        return response
    end
  end

  def label_for_payload(type)
    return 'structures' if type == 'sc:Range'
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
  headers( "Access-Control-Allow-Origin" => "*")
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
  headers( "Access-Control-Allow-Origin" => "*")
  return 415 unless request.content_type == 'application/json'

  content_type :json

  payload = JSON.parse(request.body.read)
  result = settings.notifications.insert_one payload

  JSON.pretty_generate result.inserted_id
end

# GET '/iiif/notifications' # return all notfifications
# GET '/iiif/notifications?target=<URL>'
get '/iiif/notifications/?' do
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json

  protocol  = request.ssl? ? 'https': 'http'
  host_port = request.host_with_port
  path      = request.path.chomp('/')

  this_uri  = "#{protocol}://#{host_port}#{path}"

  # Theres a target, find all notifications on it
  args = params[:target].nil? ? nil : {target: params[:target]}
  # this_uri = request.env['REQUEST_URI']
  data = { '@context': 'http://www.w3.org/ns/ldp' }
  data[:'@id'] = this_uri
  payload = ''
  data[:contains] = settings.notifications.find(args).map { |doc|

    doc['target'] = [doc['target']] unless doc['target'].respond_to? :each
    doc['target'].each do |target|
      target_uri = "#{this_uri}?target=#{target}"
      label, payload = add_to_payload(doc, target_uri, 'sc:Range')
      settings.manifests.find_one_and_update({'@id' => doc['@id']}, { '$set' => {"#{label}": payload } })
    end

    # what_i_want = this_uri.sub /\?.*$/, ''
    # "#{doc['_id']}"
    # motivation: transcription, metadata, description, painting
    { url: "#{this_uri}/#{doc['_id']}", motivation: "#{doc['motivation']}" }
  }
  JSON.pretty_generate data || {}
end

get '/iiif/test' do
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json
  data = JSON.load open('./public/test_manifest.json')

  JSON.pretty_generate data
end

# Return a specific notification
#
# GET '/iiif/notifications/:id'
get '/iiif/notifications/:id' do
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json

  doc = document_by_id :notifications, params[:id]
  doc.delete :_id

  JSON.pretty_generate doc
end
