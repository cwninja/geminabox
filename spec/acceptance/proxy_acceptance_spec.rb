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

  let(:project) {
    TestProject.new do |project|
      project.source proxy_server.url
      project.gem 'test-foo-bar-baz'
    end
  }

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

  it 'allows me to bundle install' do
    project.bundle!
    expect(project).to have_gems_installed
    expect(project).to have_gem('test-foo-bar-baz', '1.0')
  end

  it 'allows me to bundle install with a lock file' do
    project.bundle!
    project.delete_vendor!
    project.bundle!

    expect(project).to have_gems_installed
    expect(project).to have_gem('test-foo-bar-baz', '1.0')
  end

  it 'allows me to bundle install with a lock file when origin is down' do
    project.bundle!
    project.delete_vendor!
    backend_server.cleanup!
    project.bundle_deployment!
    expect(project).to have_gems_installed
    expect(project).to have_gem('test-foo-bar-baz', '1.0')
  end

end

