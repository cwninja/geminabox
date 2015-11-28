require 'sinatra'
require 'geminabox/gem_store'

class Geminabox::Server < Sinatra::Base
  attr_reader :gem_store
  def initialize(gem_store)
    super()
    @gem_store = Geminabox::GemStore(gem_store)
  end

  get'/' do
    "*shrug*"
  end

  get '/api/v1/dependencies' do
    if gems = indexed_gems
      content_type "application/octet-stream"
      Marshal.dump(gems.map(&:to_hash))
    end
  end

  get '/api/v1/dependencies.json' do
    if gems = indexed_gems
      content_type "application/json"
      JSON.dump(gems.map(&:to_hash))
    end
  end

  get "/quick/Marshal.4.8/:name.gemspec.rz" do
    spec = gem_store.get_spec(params[:name])
    io = Zlib::Deflate.deflate(Marshal.dump(spec))
    content_type "application/octet-stream"
    io
  end

  get '/gems/:file.gem' do
    io = gem_store.get(params[:file])
    content_type "application/octet-stream"
    io
  end

  Geminabox::LEGACY_PATHS.each do |path|
    get path do
      [501, {'Content-Type' => 'text/plain'}, ["Not implemented.\nGeminabox only supports installing gems."]]
    end
  end

  post '/gems' do
    if params[:file]
      gem_store.add params[:file][:tempfile]
    else
      gem_store.add request.body
    end
    201
  end

protected
  def indexed_gems
    if gems = params["gems"]
      gems = params["gems"].split(",")
      gem_store.find_gem_versions(gems)
    end
  end

end
