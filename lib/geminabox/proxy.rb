require 'faraday'

class Geminabox::Proxy < Sinatra::Base
  set :show_exceptions, :after_handler

  attr_reader :proxy_url, :file_store

  def initialize(proxy_url, file_store)
    @proxy_url, @file_store = proxy_url, file_store
    @@metadata_cache = Hash.new{|h,k| h[k] = [] }
    super()
  end

  get "/" do
    content_type "text/plain"
    "Proxying #{proxy_url}"
  end

  get "/gems/:name.gem" do
    if file_store.has_gem?(params[:name])
      io = file_store.get(params[:name])
      content_type "application/octet-stream"
      io
    else
      response = connection.get("gems/#{params[:name]}.gem")
      file_store.add StringIO.new(response.body)
      [response.status, response.headers, response.body]
    end
  end

  get "/quick/Marshal.4.8/:name.gemspec.rz" do
    if file_store.has_gem?(params[:name])
      Zlib::Deflate.deflate(Marshal.dump(file_store.get_spec(params[:name])))
    else
      response = connection.get("quick/Marshal.4.8/#{params[:name]}.gemspec.rz")
      [response.status, response.headers, response.body]
    end
  end

  get '/api/v1/dependencies' do
    if params[:gems]
      begin
        response = connection.get('api/v1/dependencies', request.GET)

        if response.success?
          deps = Marshal.load(response.body)
          @@metadata_cache.merge!(deps.group_by{|v| v[:name] })
        end

        [response.status, response.headers, response.body]
      rescue Faraday::ConnectionFailed
        content_type "application/octet-stream"
        specs = @@metadata_cache.values_at(*params[:gems].split(","))
        raise if specs.any?(&:empty?)
        Marshal.dump(specs.inject(:+))
      end
    end
  end

  def connection
    @connection ||= create_connection
  end

  def create_connection
    Faraday.new(url: proxy_url)
  end

  error do
    [500, "Whoops"]
  end

  error Faraday::ConnectionFailed do
    [503, "Connection failed"]
  end
end
