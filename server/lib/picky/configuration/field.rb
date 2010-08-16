module Configuration

  class Field
    attr_reader :name, :indexed_field, :virtual
    attr_accessor :type # convenience
    def initialize name, options = {}
      @name            = name
      
      # TODO Dup the options?
      
      @indexer_class   = options.delete(:indexer)   || Indexers::Default
      @tokenizer_class = options.delete(:tokenizer) || Tokenizers::Index # Default
      
      @indexed_field   = options.delete(:indexed_field) || name # TODO Rename to indexed_as?
      @virtual         = options.delete(:virtual)       || false
      
      # Note: Moved to Bundle.
      #
      # @weights         = options[:weights]       || Cacher::Weights::Default
      # @partial         = options[:partial]       || Cacher::Partial::Default
      # @similarity      = options[:similarity]    || Cacher::Similarity::Default
      
      # TODO Replace by add.
      #
      # Query::Qualifiers.instance << Query::Qualifier.new(name, options.delete(:qualifiers)) if options[:qualifiers]
      Query::Qualifiers.add(name, options[:qualifiers]) if options[:qualifiers]
      
      # @remove          = options[:remove]        || false
      # @filter          = options[:filter]        || true
      
      @options = options
    end
    def generate
      Index::Category.new self.name, type, @options
    end
    # TODO Duplicate code in bundle. Move to application.
    #
    # TODO Move to type, and use in bundle from there.
    #
    def search_index_root
      File.join SEARCH_ROOT, 'index'
    end
    # TODO Move to config. Duplicate Code in field.rb.
    #
    def cache_directory
      File.join search_index_root, SEARCH_ENVIRONMENT, type.name.to_s
    end
    def search_index_file_name
      File.join cache_directory, "#{type.name}_#{name}_index.txt"
    end
    def index
      indexer.index
    end
    def cache
      generate.generate_caches
    end
    def indexer
      @indexer || @indexer = @indexer_class.new(indexed_field, type, self)
    end
    def tokenizer
      @tokenizer || @tokenizer = @tokenizer_class.new # TODO Make instances.
    end
    def virtual?
      !!virtual
    end
  end

end