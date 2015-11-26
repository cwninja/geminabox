require 'bundler'

RSpec.describe 'using bundler with Geminabox server' do
  let(:server) {
    TestServer.new do |server|
      server.gem 'test-foo-bar-baz', '1.0', deps: { othertest: '~>1.0.0' }
      server.gem 'othertest', '1.0.1'
      server.gem 'othertest', '0.0.1'
    end
  }

  let(:project) { TestProject.new }

  around do |example|
    server.run do
      project.run do
        example.call
      end
    end
  end

  it 'installs the gem test' do
    project.gem_install 'test-foo-bar-baz', server.url
  end
end
