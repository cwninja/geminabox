RSpec.describe "Geminabox::SpecExtractor" do
  SpecExtractor = Geminabox::SpecExtractor

  it "gets the spec from a gem file IO stream" do
    spec = SpecExtractor.call(GemFactory.gem("test", "1.2.3"))
    expect(spec.name).to eq 'test'
    expect(spec.version.to_s).to eq '1.2.3'
  end

  it "throws an error when the gem is garbage" do
    expect{ SpecExtractor.call(StringIO.new("BLA")) }.to raise_error Geminabox::BadGemfile
  end

  it "throws an ArgumentError when passed not an IO" do
    expect{ SpecExtractor.call("BLA") }.to raise_error ArgumentError
  end
end
