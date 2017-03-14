
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

configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'iiif-notifications')
  set :mongo_db, db
end

get '/' do
  'Hello, world!'
end

get '/iiif/:name/manifest' do
  at_id = "http://library.upenn.edu/iiif/#{params[:name]}/manifest"

  manifest = settings.mongo_db[:manifests].find({'@id': at_id}).to_a.first

  return 404 if manifest.nil?

  headers 'Link' => '</notifications>; rel="http://www.w3.org/ns/ldp#inbox"'
  content_type :json

  JSON.pretty_generate manifest
end

post '/notifications' do
  payload = JSON.parse(request.body.read)

  notifications = Notifications.new NOTIFICATIONS_FILE
  notifications.add_notification payload

  content_type :json
  # notifications.all.to_json
end

post '/post' do
  payload = params
  payload = JSON.parse(request.body.read).symbolize_keys

  notifications = Notifications.new NOTIFICATIONS_FILE
  notifications.add_notification payload

  logger.info "Saving #{payload[:path]} with #{payload[:meta]}"

  file = load_app.sitemap.find_resource_by_path payload[:path]
end

