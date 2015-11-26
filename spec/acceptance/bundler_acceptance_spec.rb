require 'bundler'

RSpec.describe 'using bundler with Geminabox server' do
  let(:server) {
    TestServer.gem_store do |server|
      server.gem 'test', '1.0', deps: { othertest: '~>1.0.0' }
      server.gem 'othertest', '1.0.1'
      server.gem 'othertest', '0.0.1'
    end
  }

  let(:project) {
    TestProject.new do |project|
      project.source server.url
      project.gem 'test'
    end
  }

  around do |example|
    server.run do
      project.run do
        example.call
      end
    end
  end

  it 'installs the gem test' do
    project.bundle!
    expect(project).to have_gems_installed
    expect(project).to have_gem('test', '1.0')
    expect(project).to have_gem('othertest', '1.0.1')
  end

  it 'installs the gem test after removing vendor' do
    project.bundle!
    project.delete_vendor!
    expect(project).not_to have_gems_installed
    project.bundle!
    expect(project).to have_gems_installed
  end
end
