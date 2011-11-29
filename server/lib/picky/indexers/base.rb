# encoding: utf-8
#
module Picky

  module Indexers

    #
    #
    class Base

      attr_reader :index_or_category

      delegate :source,
               :to => :index_or_category

      def initialize index_or_category
        @index_or_category = index_or_category
      end

      # Starts the indexing process.
      #
      def index categories
        check_source
        categories.empty
        process categories do |file|
          notify_finished file
        end
        categories.cache
      end

      def check_source # :nodoc:
        raise "Trying to index without a source for #{@index_or_category.name}." unless source
      end

      def notify_finished file
        timed_exclaim %Q{"#{@index_or_category.identifier}": Tokenized -> #{file.path.gsub("#{PICKY_ROOT}/", '')}.}
      end

    end

  end

end