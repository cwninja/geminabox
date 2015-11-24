class Geminabox::GemFileStore
  include Geminabox::FilenameGenerator

  def initialize(root_path)
    @root_path = root_path
  end

  def add(uploaded_file, name)
    IO.copy_stream(uploaded_file, @root_path.join(name))
  end

  def get(gem_full_name)
    get_path(gem_full_name).open
  end

  def delete(name, version, platform = 'ruby')
    gem_path = path(name, version, platform)
    gem_path.delete if gem_path.exist?
  end

  def has_gem?(gem_full_name, version = nil, platform = "ruby")
    path(gem_full_name, version, platform).exist?
  end

protected
  def path(*gem_full_name)
    filename = gem_filename(*gem_full_name)
    @root_path.join(filename)
  end

  def get_path(gem_full_name)
    pathname = path(gem_full_name)
    pathname.exist? or
      raise Geminabox::GemNotFound.new("Gem #{gem_full_name} not found")
    pathname
  end

end
