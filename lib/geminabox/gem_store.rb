require "pathname"
require "rubygems/package"
require "geminabox/filename_generator"
require "geminabox/gem_file_store"
require "sequel"

# A GemStore should return a path on the local file system where the referenced
# Gem can be found.
class Geminabox::GemStore
  def get(*args)
    @file_store.get(*args)
  end

  def has_gem?(*args)
    @file_store.has_gem?(*args)
  end

  def add(io)
    raise ArgumentError, "Expected IO object" unless io.respond_to? :read
    Tempfile.create('gem', Dir.tmpdir, encoding: 'ascii-8bit') do |tempfile|
      IO.copy_stream(io, tempfile)
      tempfile.close
      gem = Gem::Package.new(tempfile.path)
      file_name = gem.spec.file_name
      @file_store.add(tempfile.path, file_name)

      indexed_gem = Geminabox::IndexedGem.new(
        gem.spec.name,
        gem.spec.version,
        gem.spec.platform
      )
      @db.transaction do
        gem_id = @db[:gems].insert(
          name: indexed_gem.name,
          version: indexed_gem.version,
          platform: indexed_gem.platform
        )

        deps = gem.spec.dependencies.select{|dep|
          dep.type == :runtime
        }.map{|dep|
          {
            dependency_name: dep.name,
            dependency_number: dep.requirement.to_s,
            gem_id: gem_id,
          }
        }

        @db[:dependencies].multi_insert(deps)
      end
    end
  rescue Gem::Package::FormatError
    raise Geminabox::BadGemfile, "Could not process uploaded gemfile."
  end

  def find_gem_versions(names)
    @db[:gems].where(name: names).map{|row|
      deps = @db[:dependencies].where(gem_id: row[:id]).each_with_object({}){|dependencies_row, hash|
        hash[dependencies_row[:dependency_name]] = dependencies_row[:dependency_number]
      }
      Geminabox::IndexedGem.new(row[:name], row[:version], row[:platform], deps)
    }
  end

  def delete(name, version, platform = 'ruby')
    indexed_gem = Geminabox::IndexedGem.new(name, version, platform)
    @db[:gems].where(
      name: indexed_gem.name,
      version: indexed_gem.version,
      platform: indexed_gem.platform
    ).delete
    @file_store.delete(name, version, platform)
  end

protected
  def initialize(path)
    @root_path = Pathname.new(path)
    @file_store = Geminabox::GemFileStore.new(@root_path)
    database_path = @root_path.join("database.sqlite3")
    @db = Sequel.connect("sqlite://#{database_path}")
    if not database_path.exist?
      @db.create_table :gems do
        primary_key :id
        String :name
        String :version
        String :platform
        index [:name, :version, :platform], unique: true
        index :name
      end

      @db.create_table :dependencies do
        primary_key :id
        foreign_key :gem_id, :gems, on_delete: :cascade
        String :dependency_name
        String :dependency_number
      end
    end
  end

end

def Geminabox::GemStore(path)
  if path.is_a? String or path.is_a? Pathname
    Geminabox::GemStore.new(path)
  else
    path
  end
end
