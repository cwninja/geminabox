require 'rack/test'

RSpec.describe Geminabox::Server do
  include Rack::Test::Methods

  let(:gem_store) {
    instance_double(Geminabox::GemStore, get: StringIO.new('hello'))
  }

  let(:app) {
    Geminabox.app(gem_store)
  }

  describe "GET /gems/:file.gem" do
    it 'sets the content type' do
      get "/gems/example-1.0.0.gem"
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq "application/octet-stream"
    end

    it 'streams the response' do
      get "/gems/example-1.0.0.gem"
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "hello"
    end
  end

  describe "GET /api/v1/dependencies" do
    it "returns an empty string when no gems listed" do
      get "/api/v1/dependencies"
      expect(last_response.status).to eq 200
      expect(last_response.body).to be_empty
    end

    it "returns a marshaled string when dependencies are available" do
      expect(gem_store).to receive(:find_gem_versions)
        .with(["name"])
        .and_return([
          Geminabox::IndexedGem.new("name", "1.1.1", "ruby"),
          Geminabox::IndexedGem.new("name", "1.1.2", "ruby"),
        ])
      get "/api/v1/dependencies?gems=name"
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/octet-stream'
      expect(Marshal.load(last_response.body)).to eq [
        {name: "name", number: "1.1.1", platform: "ruby", dependencies: []},
        {name: "name", number: "1.1.2", platform: "ruby", dependencies: []},
      ]
    end
  end

  describe "GET /" do
    it "returns a 200 OK" do
      get "/"
      expect(last_response.status).to eq 200
    end
  end

  describe "POST /gems" do
    it "adds the gem to the repository when posted as a application/octet-stream" do
      input_file = StringIO.new("hello")
      expect(gem_store).to receive(:add).with(input_file)
      post "/gems", {}, "content-type" => "application/octet-stream", "rack.input" => input_file
      expect(last_response.status).to eq 201
    end

    it "adds the gem to the repository when posted as a file attachment" do
      expect(gem_store).to receive(:add){|a| expect(a.read).to eq "hello" }
      upload = Rack::Test::UploadedFile.new(@file.path, "application/octet-stream")
      post "/gems", file: upload
      expect(last_response.status).to eq 201
    end

    around do |example|
      Tempfile.open('gemfile') do |f|
        f.write "hello"
        f.close
        @file = f
        example.call
      end
    end
  end
end
