class Geminabox::GemMetadataStore
  def initialize(database_path)
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

  def delete(name, version, platform = 'ruby')
    @db[:gems].where(
      name: name,
      version: version,
      platform: platform
    ).delete
  end

  def find_gem_versions(names)
    @db[:gems].where(name: names).map{|row|
      deps = @db[:dependencies].where(gem_id: row[:id]).each_with_object({}){|dependencies_row, hash|
        hash[dependencies_row[:dependency_name]] = dependencies_row[:dependency_number]
      }
      Geminabox::IndexedGem.new(row[:name], row[:version], row[:platform], deps)
    }
  end

  def add(spec)
    indexed_gem = Geminabox::IndexedGem.new(
      spec.name,
      spec.version,
      spec.platform
    )
    @db.transaction do
      gem_id = @db[:gems].insert(
        name: indexed_gem.name,
        version: indexed_gem.version,
        platform: indexed_gem.platform
      )

      deps = spec.dependencies.select{|dep|
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
end
