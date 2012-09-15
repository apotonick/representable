require 'representable/binding'

module Representable
  module XML
    module ObjectBinding
      include Binding::Object
      
      def serialize_method
        :to_node
      end
      
      def deserialize_method
        :from_node
      end
      
      def deserialize_node(node)
        deserialize(node)
      end
      
      def serialize_node(node, value)
        serialize(value)
      end
    end
    
    
    class PropertyBinding < Binding
      def initialize(definition)
        super
        extend ObjectBinding if definition.typed? # FIXME.
      end
      
      def write(parent, value, options={})
        wrap_node = parent
        
        if wrap = definition.options[:wrap]
          parent << wrap_node = node_for(parent, wrap)
        end

        wrap_node << serialize_for(value, parent)
      end
      
      def read(node)
        selector  = "./#{xpath}"
        selector  = "./#{definition.options[:wrap]}/#{xpath}" if definition.options[:wrap]
        nodes     = node.search(selector)

        return FragmentNotFound if nodes.size == 0 # TODO: write dedicated test!
        
        deserialize_from(nodes)
      end
      
      # Creates wrapped node for the property.
      def serialize_for(value, parent)
      #def serialize_for(value, parent, tag_name=definition.from)
        node = node_for(parent, definition.from)
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

      def node_for(parent, name)
        Nokogiri::XML::Node.new(name.to_s, parent.document)
      end
    end
    
    class CollectionBinding < PropertyBinding
      def serialize_for(value, parent)
        # return NodeSet so << works.
        set_for(parent, value.collect { |item| super(item, parent) })
      end
      
      def deserialize_from(nodes)
        nodes.collect do |item|
          deserialize_node(item)
        end
      end

    private
      def set_for(parent, nodes)
        Nokogiri::XML::NodeSet.new(parent.document, nodes)
      end
    end
    
    
    class HashBinding < CollectionBinding
      def serialize_for(value, parent)
        set_for(parent, value.collect do |k, v|
          node = node_for(parent, k)
          serialize_node(node, v)
        end)
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
      def write(parent, value, options={})  # DISCUSS: is it correct overriding #write here?
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
      
      def write(parent, value, options={})
        serialize_for(value, parent)
      end
    end
  end
end
