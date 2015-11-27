require 'bundler'

RSpec.describe 'Running Geminabox as a caching proxy' do
  let(:backend_server) {
    TestServer.gem_store do |server|
      server.gem 'test-foo-bar-baz', '1.0', deps: { othertest: '~>1.0.0' }
      server.gem 'othertest', '1.0.1'
      server.gem 'othertest', '0.0.1'
    end
  }

  let(:proxy_server) {
    TestServer.gem_proxy(backend_server.url)
  }

  let(:project) { TestProject.new }

  around do |example|
    backend_server.run do
      proxy_server.run do
        project.run do
          example.call
        end
      end
    end
  end

  it 'installs the gem test' do
    project.gem_install 'test-foo-bar-baz', proxy_server.url
  end
end

