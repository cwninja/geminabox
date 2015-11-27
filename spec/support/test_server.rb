require 'net/http'
require 'webrick'

module TestServer
  # Create a new GemStoreServer
  def self.gem_store(&block)
    GemStoreServer.new(&block)
  end

  def self.gem_proxy(backend)
    GemProxyServer.new(backend)
  end

  class Generic
    def run
      start_server!
      wait_until_booted!
      yield
      cleanup!
    end

    def cleanup!
      Thread.kill(@thread)
    end

    def url
      "http://127.0.0.1:#{@port}"
    end

    def http_client(&block)
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, &block)
    end

  protected
    def start_server!
      @port = find_available_port
      @thread = Thread.start do
        Rack::Handler::WEBrick.run app, Port: @port, Host: '127.0.0.1'
      end
    end

    def find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server.close if server
    end

    def booted?
      ::Net::HTTP.get_response("127.0.0.1", '/', @port)
      return true
    rescue Errno::ECONNREFUSED, Errno::EBADF
      return false
    end

    def wait_until_booted!
      start_time = Time.now
      loop do
        @thread.join unless @thread.alive?
        return if booted?
        raise TimeoutError.new if (Time.now - start_time) > 2
        sleep(0.05)
      end
    end
  end

  class GemStoreServer < Generic
    attr_reader :gem_store

    def initialize(&block)
      @fixture_setup = block
    end

    def run(&block)
      create_gemstore!
      setup_gems!
      super(&block)
    end

  protected
    def app
      Geminabox::gem_store(@dir)
    end

    def create_gemstore!
      @dir = Pathname.new(Dir.mktmpdir)
      @gem_store = Geminabox::GemStore(@dir)
    end

    def setup_gems!
      gemset_factory = GemsetFactory.new(gem_store)
      @fixture_setup.call(gemset_factory)
    end

    def cleanup!
      super
      FileUtils.remove_entry @dir
    end
  end

  class GemProxyServer < Generic
    attr_reader :proxy_url

    def initialize(proxy_url)
      @proxy_url = proxy_url
    end

    def run(&block)
      create_gemstore!
      super(&block)
    end

  protected
    def app
      Geminabox::gem_proxy(@proxy_url, @gem_store)
    end

    def create_gemstore!
      @dir = Pathname.new(Dir.mktmpdir)
      @gem_store = Geminabox::GemStore(@dir)
    end

    def cleanup!
      super
      FileUtils.remove_entry @dir
    end
  end

end
