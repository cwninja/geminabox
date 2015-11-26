require "pathname"
require "rubygems/package"
require "geminabox/filename_generator"
require "geminabox/gem_file_store"
require "geminabox/gem_metadata_store"
require "geminabox/spec_extractor"
require "sequel"

# A GemStore should return a path on the local file system where the referenced
# Gem can be found.
class Geminabox::GemStore
  def get(*args)
    @file_store.get(*args)
  end

  def get_spec(*args)
    Geminabox::SpecExtractor.call(get(*args))
  end

  def has_gem?(*args)
    @file_store.has_gem?(*args)
  end

  def add(io)
    raise ArgumentError, "Expected IO object" unless io.respond_to? :read
    Tempfile.open('gem', Dir.tmpdir, encoding: 'ascii-8bit') do |tempfile|
      IO.copy_stream(io, tempfile)
      tempfile.close
      spec = Gem::Package.new(tempfile.path).spec
      @file_store.add(tempfile.path, spec.file_name)
      @metadata_store.add(spec)
    end
  rescue Gem::Package::FormatError
    raise Geminabox::BadGemfile, "Could not process uploaded gemfile."
  end

  def find_gem_versions(names)
    @metadata_store.find_gem_versions(names)
  end

  def delete(*args)
    @file_store.delete(*args)
    @metadata_store.delete(*args)
  end

protected
  def initialize(path)
    @root_path = Pathname.new(path)
    @file_store = Geminabox::GemFileStore.new(@root_path)
    @metadata_store = Geminabox::GemMetadataStore.new(
      @root_path.join("database.sqlite3")
    )
  end

end

def Geminabox::GemStore(path)
  if path.is_a? String or path.is_a? Pathname
    Geminabox::GemStore.new(path)
  else
    path
  end
end
