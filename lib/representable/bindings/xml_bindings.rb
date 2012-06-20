require 'representable/binding'

module Representable
  module XML
    module ObjectBinding
      # TODO: provide a base ObjectBinding for XML/JSON/MP.
      include Binding::Extend  # provides #serialize/#deserialize with extend.

      def serialize(object)
        super(object).to_node(:wrap => false)
      end

      def deserialize(hash)
        super(create_object).from_node(hash)
      end

      def deserialize_node(node)
        deserialize(node)
      end

      def serialize_node(node, value)
        serialize(value)
      end

      def create_object
        definition.sought_type.new
      end
    end


    class PropertyBinding < Binding
      def initialize(definition)
        super
        extend ObjectBinding if definition.typed? # FIXME.
      end

      def write(parent, value)
        parent << serialize_for(value, parent)
      end

      def read(node)
        nodes = node.search("./#{xpath}")
        return FragmentNotFound if nodes.size == 0 # TODO: write dedicated test!

        deserialize_from(nodes)
      end

      # Creates wrapped node for the property.
      def serialize_for(value, parent)
      #def serialize_for(value, parent, tag_name=definition.from)
        node =  Nokogiri::XML::Node.new(definition.from, parent.document)
        serialize_node(node, value)
      end

      def serialize_node(node, value)
        node.content = serialize(value)
        node
      end

      def deserialize_from(nodes)
        deserialize_node(nodes.first)
      end

      # DISCUSS: rename to #read_from ?
      def deserialize_node(node)
        deserialize(node.content)
      end

    private
      def xpath
        definition.from
      end
    end

    class CollectionBinding < PropertyBinding
      def write(parent, value)
        serialize_items(value, parent).each do |node|
          parent << node
        end
      end

      def serialize_items(value, parent)
        value.collect do |obj|
          serialize_for(obj, parent)
        end
      end

      def deserialize_from(nodes)
        nodes.collect do |item|
          deserialize_node(item)
        end
      end
    end


    class HashBinding < CollectionBinding
      def serialize_items(value, parent)
        value.collect do |k, v|
          node = Nokogiri::XML::Node.new(k, parent.document)
          serialize_node(node, v)
        end
      end

      def deserialize_from(nodes)
        {}.tap do |hash|
          nodes.children.each do |node|
            hash[node.name] = deserialize_node(node)
          end
        end
      end
    end

    class AttributeHashBinding < CollectionBinding
      # DISCUSS: use AttributeBinding here?
      def write(parent, value)  # DISCUSS: is it correct overriding #write here?
        value.collect do |k, v|
          parent[k] = serialize(v.to_s)
        end
        parent
      end

      def deserialize_from(node)
        {}.tap do |hash|
          node.each do |k,v|
            hash[k] = deserialize(v)
          end
        end
      end
    end


    # Represents a tag attribute. Currently this only works on the top-level tag.
    class AttributeBinding < PropertyBinding
      def read(node)
        deserialize(node[definition.from])
      end

      def serialize_for(value, parent)
        parent[definition.from] = serialize(value.to_s)
      end

      def write(parent, value)
        serialize_for(value, parent)
      end
    end
  end
end
