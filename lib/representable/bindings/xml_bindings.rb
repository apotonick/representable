module Representable
  module XML
    class Binding
      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end
      
      def read(xml)
        value_from_node(xml) or default
      end
      
    private
      def default
        ""
      end
      
      def xpath
        definition.from
      end

      def collect_for(xml)
        nodes = xml.search("./#{xpath}")
        vals  = nodes.collect { |node| yield node }
        
        definition.array? ? vals : vals.first
      end
    end
    
    
    # Represents a tag attribute.
    class AttributeBinding < Binding
      def write(xml, values)
        xml[definition.from] = values.to_s
      end

    private
      def value_from_node(xml)
        xml[definition.from]
      end
    end
    
    
    # Represents text content in a tag. # FIXME: is this tested???
    class TextBinding < Binding
      def write(xml, value)
        if definition.array?
          value.each do |v|
            add(xml.add_node(definition.from), v)
          end
        else
          add(xml.add_node(definition.from), value)
        end
      end

    private
      def value_from_node(xml)
        collect_for(xml) do |node| 
          node.content
        end
      end

      def add(dest, value)
        dest.content = value.to_s
      end
    end
    

    # Represents a tag with object binding.
    class ObjectBinding < Binding
      # Adds the ref's markup to +xml+. 
      def write(xml, value)
        if definition.array?
          write_collection(xml, value)
        else
          write_entity(xml, value)
        end
      end

    private
      def default
        []
      end
      
      # Deserializes the ref's element from +xml+.
      def value_from_node(xml)
        collect_for(xml) do |node|
          definition.sought_type.from_node(node)
        end
      end
      
      def write_collection(xml, collection)
        collection.each do |item|
          write_entity(xml, item)
        end
      end
      
      def write_entity(xml, entity)
        xml.add_child(entity.to_node)
      end
    end
  end
end
