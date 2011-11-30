require 'representable'
require 'representable/nokogiri_extensions'
require 'representable/bindings/xml_bindings'

module Representable
  module XML
    BINDING_FOR_TYPE = {
      :attr     => AttributeBinding,
      :text     => TextBinding,
    }
    
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        self.representation_wrap = true # let representable compute it.
      end
    end
    
    
    module ClassMethods
      def binding_for_definition(definition)
        (BINDING_FOR_TYPE[definition.sought_type] or ObjectBinding).new(definition)
      end
      
      # Creates a new Ruby object from XML using mapping information declared in the class.
      #
      # Accepts a block yielding the currently iterated Definition. If the block returns false 
      # the property is skipped.
      #
      # Example:
      #   band.from_xml("<band><name>Nofx</name></band>")
      def from_xml(*args, &block)
        new.from_xml(*args, &block)
      end
      
      def from_node(*args, &block)
        new.from_node(*args, &block)
      end
    end
    
    
    def from_xml(doc, *args, &block)
      node = Nokogiri::XML(doc).root
      from_node(node, *args, &block)
    end
    
    def from_node(node, options={}, &block)
      update_properties_from(node, &block)
    end
    
    # Returns a Nokogiri::XML object representing this object.
    def to_node(options={})
      root_tag = options[:wrap] || self.class.representation_wrap
      
      create_representation_with(Nokogiri::XML::Node.new(root_tag.to_s, Nokogiri::XML::Document.new))
    end
    
    def to_xml(*args)
      to_node(*args).to_s
    end
  end
end
