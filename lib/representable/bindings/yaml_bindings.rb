require 'representable/binding'

module Representable
  module YAML
    module ObjectBinding
      include Binding::Object
      
      def serialize_method
        :to_ast
      end
      
      def deserialize_method
        :from_hash
      end

      def write_scalar(value)
        value
      end
    end

    class PropertyBinding < Representable::Hash::PropertyBinding
      def self.build_for(definition, *args)
        return definition.instantiate_binding(*args)    if definition.has_binding?
        return CollectionBinding.new(definition, *args) if definition.array?
        new(definition, *args)
      end

      def initialize(*args) # FIXME. make generic.
        super
        extend ObjectBinding if typed?
      end
      
      def write(map, value)
        map.children << Psych::Nodes::Scalar.new(from)
        map.children << serialize_for(value)  # FIXME: should be serialize.
      end

      def serialize_for(value)
        write_scalar serialize(value)
      end

      def write_scalar(value)
        Psych::Nodes::Scalar.new(value.to_s)
      end
    end
    
    
    class CollectionBinding < PropertyBinding
      def serialize_for(value)
        Psych::Nodes::Sequence.new.tap do |seq|
          seq.style = Psych::Nodes::Sequence::FLOW if options[:style] == :flow
          value.each { |obj| seq.children << super(obj) }
        end
      end
      
      def deserialize_from(fragment)  # FIXME: redundant from Hash::Bindings
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end
  end
end
