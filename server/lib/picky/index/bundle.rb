# encoding: utf-8
#
module Index

  # This is the ACTUAL index.
  #
  # Handles full index, partial index, weights index, and similarity index.
  #
  class Bundle
    
    attr_reader   :name,             :category,         :type
    attr_accessor :index,            :weights,          :similarity
    attr_accessor :partial_strategy, :weights_strategy, :similarity_strategy
    
    delegate :[], :[]=, :clear, :to => :index
    
    # Path is in which directory the cache is located.
    #
    def initialize name, category, type, partial_strategy, weights_strategy, similarity_strategy
      @index      = {}
      @weights    = {}
      @similarity = {}
      
      @name     = name
      @category = category
      @type     = type
      
      @partial_strategy    = partial_strategy
      @weights_strategy    = weights_strategy
      @similarity_strategy = similarity_strategy
    end
    
    # Get the ids for the text.
    #
    def ids text
      @index[text] || []
    end
    # Get a weight for the text.
    #
    def weight text
      @weights[text]
    end
    # Get a list of similar texts.
    #
    def similar text
      code = similarity_strategy.encoded text
      code && @similarity[code] || []
    end

    # Identifier for this bundle.
    #
    def identifier
      "#{name}:#{type.name}:#{category.name}"
    end
    
    # Point to category.
    #
    def search_index_root
      File.join SEARCH_ROOT, 'index'
      # category.search_index_root
    end
    
    def size_of path
      `ls -l #{path} | awk '{print $5}'`.to_i
    end
    # Check if the cache files are there and do not have size 0.
    #
    def caches_ok?
      cache_ok?(index_cache_path) &&
      cache_ok?(similarity_cache_path) &&
      cache_ok?(weights_cache_path)
    end
    # Is the cache ok? I.e. larger than four in size.
    #
    def cache_ok? path
      size_of(path) > 0
    end
    # Raises an appropriate error message.
    #
    def raise_cache_missing what
      raise "#{what} cache for #{identifier} missing."
    end
    # Is the cache small?
    #
    def cache_small? path
      size_of(path) < 16
    end
    def warn_cache_small what
      puts "#{what} cache for #{identifier} smaller than 16 bytes."
    end
    # Check all index files and raise if necessary.
    #
    def raise_unless_cache_exists
      warn_cache_small :index      if cache_small?(index_cache_path)
      # warn_cache_small :similarity if cache_small?(similarity_cache_path)
      warn_cache_small :weights    if cache_small?(weights_cache_path)

      raise_cache_missing :index      unless cache_ok?(index_cache_path)
      raise_cache_missing :similarity unless cache_ok?(similarity_cache_path)
      raise_cache_missing :weights    unless cache_ok?(weights_cache_path)
    end

    # Copies the indexes to the "backup" directory.
    #
    def backup
      FileUtils.mkdir backup_path unless Dir.exists?(backup_path)
      FileUtils.cp index_cache_path, backup_path, :verbose => true
      FileUtils.cp similarity_cache_path, backup_path, :verbose => true
      FileUtils.cp weights_cache_path, backup_path, :verbose => true
    end
    def backup_path
      File.join File.dirname(index_cache_path), 'backup'
    end

    # Restores the indexes from the "backup" directory.
    #
    def restore
      FileUtils.cp backup_file_path_of(index_cache_path), index_cache_path, :verbose => true
      FileUtils.cp backup_file_path_of(similarity_cache_path), similarity_cache_path, :verbose => true
      FileUtils.cp backup_file_path_of(weights_cache_path), weights_cache_path, :verbose => true
    end
    def backup_file_path_of path
      dir, name = File.split path
      File.join dir, 'backup', name
    end

    # Delete the file at path.
    #
    def delete path
      `rm -Rf #{path}`
    end
    # Delete all index files.
    #
    def delete_all
      delete index_cache_path
      delete similarity_cache_path
      delete weights_cache_path
    end

    # Create directory and parent directories.
    #
    def create_directory
      FileUtils.mkdir_p cache_directory
    end
    # TODO Move to config. Duplicate Code in field.rb.
    #
    def cache_directory
      File.join search_index_root, SEARCH_ENVIRONMENT, type.name.to_s
    end

    # Generates a cache path.
    #
    def cache_path text
      File.join cache_directory, "#{name}_#{text}.dump"
    end
    def index_cache_path
      cache_path "#{category.name}_index"
    end
    def similarity_cache_path
      cache_path "#{category.name}_similarity"
    end
    def weights_cache_path
      cache_path "#{category.name}_weights"
    end

    # Loads all indexes into this category.
    #
    def load
      load_index
      load_similarity
      load_weights
    end
    def load_the index_method_name, path
      self.send "#{index_method_name}=", Marshal.load(File.open(path, "r:binary")) if File.exists? path
    end
    def load_index
      puts "#{Time.now}: Loading the index for #{identifier} from the cache."
      load_the :index, index_cache_path
    end
    def load_similarity
      puts "#{Time.now}: Loading the similarity for #{identifier} from the cache."
      load_the :similarity, similarity_cache_path
    end
    def load_weights
      puts "#{Time.now}: Loading the weights for #{identifier} from the cache."
      load_the :weights, weights_cache_path
    end

    # TODO Decide on the fate of this.
    #
    # # Generates similar index entries. If you search for bla, you will also find the blarf and vice versa.
    # #
    # # Examples:
    # #   title.generate_similar_from { :bla => :blarf }
    # #
    # # Note: Be careful with this, as it uses up a lot of memory.
    # #
    # def generate_similar_from mapping
    #   mapping.each_pair do |one, other|
    #     one_ids   = self.index[one]
    #     other_ids = self.index[other]
    #
    #     self.index[one]   += other_ids || [] if one_ids
    #     self.index[other] += one_ids || [] if other_ids
    #   end
    # end

    # Generation
    #

    # This method
    # * loads the base index from the db
    # * generates derived indexes
    # * dumps all the indexes into files
    #
    def generate_caches_from_db
      cache_from_db_generation_message
      load_from_index_file
      generate_caches_from_memory
    end
    def cache_from_db_generation_message
      puts "#{Time.now}: Generating caches from db for #{identifier}."
    end
    # Generates derived indexes from the index and dumps.
    #
    # Note: assumes that there is something in the index
    #
    def generate_caches_from_memory
      cache_from_memory_generation_message
      generate_derived
    end
    def cache_from_memory_generation_message
      puts "#{Time.now}: Generating derived caches from memory for #{identifier}."
    end

    # Generates the weights and similarity from the main index.
    #
    def generate_derived
      generate_weights
      generate_similarity
    end

    # Load the data from the db.
    #
    def load_from_index_file # TODO Load from index_file.
      clear
      retrieve
    end
    # Retrieves the data into the index.
    #
    # TODO Beautify.
    #
    def retrieve
      # TODO Make r:binary configurable!
      #
      File.open(search_index_file_name, 'r:binary') do |file|
        file.each_line do |line|
          indexed_id, token = line.split ?,,2
          token.chomp!
          token = token.to_sym
          
          initialize_index_for token
          index[token] << indexed_id.to_i
        end
      end
    end
    def initialize_index_for token
      index[token] ||= []
    end
    # TODO Duplicate code!
    #
    # TODO Use config object?
    #
    def search_index_file_name
      File.join cache_directory, "#{type.name}_#{category.name}_index.txt"
    end
    
    # Generators.
    #
    # TODO Move somewhere more fitting.
    #
    
    # Generates a new index (writes its index) using the
    # given partial caching strategy.
    #
    def generate_partial
      generator = Cacher::PartialGenerator.new self.index
      self.index = generator.generate self.partial_strategy
    end
    def generate_partial_from full_index
      self.index = full_index
      self.generate_partial
      self
    end
    # Generates a new similarity index (writes its index) using the
    # given similarity caching strategy.
    #
    def generate_similarity
      generator = Cacher::SimilarityGenerator.new self.index
      self.similarity = generator.generate self.similarity_strategy
    end
    # Generates a new weights index (writes its index) using the
    # given weight caching strategy.
    #
    def generate_weights
      generator = Cacher::WeightsGenerator.new self.index
      self.weights = generator.generate self.weights_strategy
    end

    # Saves the index in a dump file.
    #
    def dump
      dump_index
      dump_similarity
      dump_weights
    end
    def dump_index
      index.dump_to index_cache_path
    end
    def dump_similarity
      similarity.dump_to similarity_cache_path
    end
    def dump_weights
      weights.dump_to weights_cache_path
    end

  end
end