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
      def self.build_for(definition, *args)  # TODO: remove default arg.
        return definition.instantiate_binding(*args)     if definition.has_binding?
        return CollectionBinding.new(definition, *args)  if definition.array?
        return HashBinding.new(definition, *args)        if definition.hash?
        new(definition, *args)
      end

      def initialize(*args) # FIXME. make generic.
        super
        extend ObjectBinding if typed?
      end
      
      def read(hash)
        return FragmentNotFound unless hash.has_key?(from) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.
        
        fragment = hash[from]
        deserialize_from(fragment)
      end
      
      def write(hash, value)
        hash[from] = serialize_for(value)
      end
      
      def serialize_for(value)
        serialize(value)
      end
      
      def deserialize_from(fragment)
        deserialize(fragment)
      end
    end
    
    
    class CollectionBinding < PropertyBinding
      def serialize_for(value)
        # value.enum_for(:each_with_index).collect { |obj, i| serialize(obj, i) } # DISCUSS: provide ary index/hash key for representer_module_for?
        value.collect { |obj| serialize(obj) }
      end
      
      def deserialize_from(fragment)
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end
    
    
    class HashBinding < PropertyBinding
      def serialize_for(value)
        # requires value to respond to #each with two block parameters.
        {}.tap do |hsh|
          value.each { |key, obj| hsh[key] = serialize(obj) }
        end
      end
      
      def deserialize_from(fragment)
        {}.tap do |hsh|
          fragment.each { |key, item_fragment| hsh[key] = deserialize(item_fragment) }
        end
      end
    end
  end
end
