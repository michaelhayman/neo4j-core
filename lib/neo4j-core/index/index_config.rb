module Neo4j
  module Core
    module Index

      # Responsible for holding the configuration for one index
      # Is used in a DSL to configure the index.
      class IndexConfig
        attr_reader :_trigger_on, :_index_names, :entity_type, :_index_type, :_numeric_types, :_decl_type

        # @param [:rel, :node] entity_type the type of index
        def initialize(entity_type)
          @entity_type = entity_type
          @_index_type = {}
          @_numeric_types = []
          @_trigger_on = {}
          @_decl_type = {}
        end

        def inherit_from(clazz)
          c = clazz._indexer.config
          raise "Can't inherit from different index type #{@entity_type} != #{c.entity_type}" if @entity_type != c.entity_type
          @_index_type.merge!(c._index_type)
          @_numeric_types += c._numeric_types
          @_decl_type.merge!(c._decl_type)
        end

        # Specifies which property and values the index should be triggered on.
        # Used in the Index DSL.
        # @see Neo4j::Core::Index::ClassMethods#node_indexer
        def trigger_on(hash)
          merge_and_to_string(@_trigger_on, hash)
        end

        # Specifies the types of the properties being indexed so that the proper sort order can be applied.
        # Used in the Index DSL.
        # @see Neo4j::Core::Index::ClassMethods#node_indexer
        def decl_type(prop_and_type_hash)
          merge_and_to_string(@_decl_type, prop_and_type_hash)
        end

        # Specifies an index with configuration
        # Used in the Index DSL.
        # @param [Hash] args the field and its configuration TODO
        # @see Neo4j::Core::Index::ClassMethods#index
        def index(args)
          conf = args.last.kind_of?(Hash) ? args.pop : {}

          args.uniq.each do |field|
            @_index_type[field.to_s] = conf[:type] || :exact
            @_numeric_types << field.to_s if conf[:numeric] == true
          end
        end

        # @return [Class,nil] the specified type of the property or nil
        # @see #decl_type
        def decl_type_on(prop)
          @_decl_type[prop]
        end

        # @return [true, false] if the props can/should trigger an index operation
        def trigger_on?(props)
          @_trigger_on.each_pair { |k, v| break true if (a = props[k]) && (v.include?(a)) } == true
        end

        # @return the index name for the lucene index given a type
        def index_name_for_type(type)
          _prefix_index_name + @_index_names[type]
        end

        # Defines the
        def prefix_index_name(&block)
          @prefix_index_name_block = block
        end

        def _prefix_index_name
          @prefix_index_name_block.nil? ? "" : @prefix_index_name_block.call
        end

        def index_names(hash)
          @_index_names = hash
        end


        def rm_index_config
          @_index_type = {}
          @_numeric_types = []
        end

        def index_type(field)
          @_index_type[field.to_s]
        end

        def has_index_type?(type)
          @_index_type.values.include?(type)
        end

        def fields
          @_index_type.keys
        end

        def index?(field)
          @_index_type.include?(field.to_s)
        end

        def numeric?(field)
          return true if @_numeric_types.include?(field)
        end

        private

        def merge_and_to_string(existing_hash, new_hash)
          new_hash.each_pair do |k, v|
            existing_hash[k.to_s] ||= Set.new
            existing_hash[k.to_s].merge(v.is_a?(Array) ? v : [v])
          end
        end
      end
    end
  end
end
