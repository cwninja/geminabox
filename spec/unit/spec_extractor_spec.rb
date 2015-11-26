RSpec.describe "Geminabox::SpecExtractor" do
  SpecExtractor = Geminabox::SpecExtractor
  it "gets the spec from a gem file IO stream" do
    spec = SpecExtractor.call(GemFactory.gem("test", "1.2.3"))
    expect(spec.name).to eq 'test'
    expect(spec.version.to_s).to eq '1.2.3'
  end
end
