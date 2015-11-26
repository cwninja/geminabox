require 'net/http'

RSpec.describe "Uploading a gem file to the server" do
  describe "a gem upload in raw push format" do
    it "accepts the raw upload" do
      server.http_client do |http|
        request = Net::HTTP::Post.new("/gems")
        request.content_type = 'application/octet-stream'
        request.body = example_gem_content

        response = http.request(request)

        expect(response.code.to_i).to eq 201
      end

      server.http_client do |http|
        gem = http.get("/gems/foo-1.1.1.gem").body

        expect(gem).to eq example_gem_content
      end
    end
  end

  let(:example_gem_content) {
    GemFactory.gem('foo', '1.1.1').read
  }

  let(:server) {
    TestServer.gem_store{}
  }

  around do |example|
    server.run do
      example.run
    end
  end
end
