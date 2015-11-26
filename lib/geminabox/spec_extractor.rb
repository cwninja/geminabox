require "archive/tar/minitar"
require "yaml"

Geminabox::SpecExtractor = ->(io){
  Archive::Tar::Minitar::Reader.open(io) do |tar|
    tar.each do |entry|
      if entry.full_name == "metadata.gz"
        return YAML.load(Zlib::GzipReader.new(entry).read)
      end
    end
  end
  nil
}
