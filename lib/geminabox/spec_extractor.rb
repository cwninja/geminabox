require "archive/tar/minitar"
require "yaml"

Geminabox::SpecExtractor = ->(io){
  raise ArgumentError, "Bad io object" unless io.respond_to? :read
  spec = nil
  Archive::Tar::Minitar::Reader.open(io) do |tar|
    tar.each do |entry|
      if entry.full_name == "metadata.gz"
        spec = YAML.load(Zlib::GzipReader.new(entry).read)
        break
      end
    end
  end
  spec or raise Geminabox::BadGemfile.new("Could not find a metadata.rz file")
}
