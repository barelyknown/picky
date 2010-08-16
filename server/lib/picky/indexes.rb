module Indexes

  mattr_accessor :configuration, :types, :type_mapping

  # Takes a snapshot of the originating table.
  #
  def self.take_snapshot *args
    configuration.take_snapshot *args
  end
  # Runs the indexers in parallel (index + cache).
  #
  def self.index
    Indexes.take_snapshot

    # Run in parallel.
    #
    puts "Indexing using #{Cores.max_processors} processors."
    Cores.forked self.fields, :randomly => true do |field|
      # Reestablish DB connection.
      DB::Source.connect
      field.index
      field.cache
    end
  end
  def self.index_solr
    configuration.index_solr
  end
  
  # Returns an array of fields.
  #
  # TODO Rewrite.
  #
  def self.fields
    result = []
    configuration.types.each do |type|
      type.fields.inject(result) do |total, field|
        total << field
      end
    end
    result
  end
  
  # Backup / Restore.
  #
  def self.backup_caches
    each_category do |category|
      category.full.backup
      category.partial.backup
    end
  end
  def self.restore_caches
    each_category do |category|
      category.full.restore
      category.partial.restore
    end
  end
  
  # Use these if you need to index / cache a single index.
  #
  def self.generate_index_only type_name, field_name
    Indexes.configuration.types.each do |type|
      next unless type_name == type.name
      type.fields.each do |field|
        field.index if field_name == field.name
      end
    end
  end
  def self.generate_cache_only type_name, category_name
    Indexes.each do |type|
      next unless type_name == type.name
      type.categories.each do |category|
        category.generate_caches if category_name == category.name
      end
    end
  end
  
  # Runs the index cache generation.
  #
  # TODO Needed?
  #
  def self.generate_caches
    each &:generate_caches
  end
  # Loads all indexes from the caches.
  #
  def self.load_from_cache
    each &:load_from_cache
  end
  def self.reload
    load_from_cache
  end
  
  # Checks if the caches are there.
  #
  def self.check_caches
    each do |type|
      type.categories.each do |category|
        category.full.raise_unless_cache_exists
        category.partial.raise_unless_cache_exists
      end
    end
  end
  
  # Removes the cache files.
  #
  def self.clear_caches
    each do |type|
      type.categories.each do |category|
        category.full.delete_all
        category.partial.delete_all
      end
    end
  end

  # Creates the directory structure for the indexes.
  #
  # TODO Should be on type?
  #
  def self.create_directory_structure
    each_bundle do |full, partial|
      full.create_directory
      partial.create_directory
    end
  end

  # 
  #
  def self.clear
    self.types = []
  end
  
  
  def self.each &block
    types.each &block
  end
  def self.each_category &block
    each do |type|
      type.categories.each &block
    end
  end
  def self.each_bundle
    each_category do |category|
      yield category.full, category.partial
    end
  end
  
  # Loads all index definitions.
  #
  def self.setup
    self.types        ||= []
    self.type_mapping ||= {}
    configuration.types.each do |type|
      add type.generate
    end
  end
  def self.add type
    self.type_mapping[type.name] = type
    self.types << type
  end
  def self.[] type_name
    self.type_mapping[type_name]
  end
  
end