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
      def self.build_for(definition, *args)
        return definition.instantiate_binding(*args)         if definition.has_binding?
        return CollectionBinding.new(definition, *args)      if definition.array?
        return HashBinding.new(definition, *args)            if definition.hash? and not definition.options[:use_attributes] # FIXME: hate this.
        return AttributeHashBinding.new(definition, *args)   if definition.hash? and definition.options[:use_attributes]
        return AttributeBinding.new(definition, *args)       if definition.attribute
        new(definition, *args)
      end

      def initialize(*args)
        super
        extend ObjectBinding if typed? # FIXME.
      end
      
      def write(parent, value)
        wrap_node = parent
        
        if wrap = options[:wrap]
          parent << wrap_node = node_for(parent, wrap)
        end

        wrap_node << serialize_for(value, parent)
      end
      
      def read(node)
        nodes = find_nodes(node)
        return FragmentNotFound if nodes.size == 0 # TODO: write dedicated test!
        
        deserialize_from(nodes)
      end
      
      # Creates wrapped node for the property.
      def serialize_for(value, parent)
      #def serialize_for(value, parent, tag_name=definition.from)
        node = node_for(parent, from)
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
        from
      end

      def find_nodes(doc)
        selector  = xpath
        selector  = "#{options[:wrap]}/#{xpath}" if options[:wrap]
        nodes     = doc.xpath(selector)
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
        deserialize(node[from])
      end
      
      def serialize_for(value, parent)
        parent[from] = serialize(value.to_s)
      end
      
      def write(parent, value)
        serialize_for(value, parent)
      end
    end
  end
end
