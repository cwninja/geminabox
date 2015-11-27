require 'faraday'

class Geminabox::Proxy < Sinatra::Base
  attr_reader :proxy_url, :file_store

  def initialize(proxy_url, file_store)
    @proxy_url, @file_store = proxy_url, file_store
    super()
  end

  get "/" do
    content_type "text/plain"
    "Proxying #{proxy_url}"
  end

  get "/gems/:name.gem" do
    response = connection.get("/gems/#{params[:name]}.gem")
    [response.status, response.headers, response.body]
  end

  get "/*" do
    response = connection.get(params[:splat].join("/"), request.GET)
    [response.status, response.headers, response.body]
  end

  def connection
    @connection ||= create_connection
  end

  def create_connection
    Faraday.new(url: proxy_url)
  end
end
