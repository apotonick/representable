require 'representable/binding'

module Representable
  module Hash
    module ObjectBinding
      include Binding::Object
      
      def serialize_method
        :to_hash
      end
      
      def deserialize_method
        :from_hash
      end
    end
    
    
    class PropertyBinding < Representable::Binding
      def initialize(definition) # FIXME. make generic.
        super
        extend ObjectBinding if definition.typed?
      end
      
      def read(hash)
        return FragmentNotFound unless hash.has_key?(definition.from) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.
        
        fragment = hash[definition.from]
        deserialize_from(fragment)
      end
      
      def write(hash, value, options={})
        hash[definition.from] = serialize_for(value, options)
      end
      
      def serialize_for(value, options={})
        serialize(value)
      end
      
      def deserialize_from(fragment)
        deserialize(fragment)
      end
    end
    
    
    class CollectionBinding < PropertyBinding
      def serialize_for(value, options={})




        if definition.block
          value = value.instance_exec(options, &definition.block)
        end

        if options[:use_as_is][definition.name]
          serialize(value, options)
        else
          value.collect { |obj| serialize(obj, options) }
        end
      end
      
      def deserialize_from(fragment)
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end
    
    
    class HashBinding < PropertyBinding
      def serialize_for(value, options={})
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
