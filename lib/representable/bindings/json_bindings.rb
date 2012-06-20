require 'representable/binding'

module Representable
  module JSON
    module ObjectBinding
      # TODO: provide a base ObjectBinding for XML/JSON/MP.
      include Binding::Extend  # provides #serialize/#deserialize with extend.

      def serialize(object)
        super(object).to_hash(:wrap => false)
      end

      def deserialize(hash)
        super(create_object).from_hash(hash)
      end

      def create_object
        definition.sought_type.new
      end
    end


    class JSONBinding < Representable::Binding
      def initialize(definition) # FIXME. make generic.
        super
        extend ObjectBinding if definition.typed?
      end

      def read(hash)
        return FragmentNotFound unless hash.has_key?(definition.from) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.

        fragment = hash[definition.from]
        deserialize_from(fragment)
      end

      def write(hash, value)
        hash[definition.from] = serialize_for(value)
      end
    end


    class PropertyBinding < JSONBinding
      def serialize_for(value)
        serialize(value)
      end

      def deserialize_from(fragment)
        deserialize(fragment)
      end
    end


    class CollectionBinding < JSONBinding
      def serialize_for(value)
        value.collect { |obj| serialize(obj) }
      end

      def deserialize_from(fragment)
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end


    class HashBinding < JSONBinding
      def serialize_for(value)
        # requires value to respond to #each with two block parameters.
        {}.tap do |hash|
          value.each { |key, obj| hash[key] = serialize(obj) }
        end
      end

      def deserialize_from(fragment)
        fragment.each { |key, item_fragment| fragment[key] = deserialize(item_fragment) }
      end
    end
  end
end
