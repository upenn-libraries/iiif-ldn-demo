
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'

directories = %w(lib)

directories.each do |directory|
  Dir["#{File.dirname(__FILE__)}/#{directory}/*.rb"].each do |file|
    require file
  end
end

MANIFESTS_DIR = File.expand_path '../manifests', __FILE__

get '/' do
  'Hello world!'
end

get '/iiif/:name/manifest' do
  manifest = Manifest.new MANIFESTS_DIR, params[:name]

  return 404 unless manifest.exists?

  content_type :json

  manifest.render
end