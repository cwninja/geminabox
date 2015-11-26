require "archive/tar/minitar"
require "yaml"

Geminabox::SpecExtractor = ->(io){
  raise ArgumentError, "Bad io object" unless io.respond_to? :read
  Archive::Tar::Minitar::Reader.open(io) do |tar|
    tar.each do |entry|
      if entry.full_name == "metadata.gz"
        return YAML.load(Zlib::GzipReader.new(entry).read)
      end
    end
  end
  raise Geminabox::BadGemfile.new("Could not find a metadata.rz file")
}
