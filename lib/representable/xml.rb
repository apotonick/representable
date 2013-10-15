require 'representable'
require 'representable/bindings/xml_bindings'
require 'nokogiri'

module Representable
  module XML
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        self.representation_wrap = true # let representable compute it.
      end
    end


    module ClassMethods
      # Creates a new Ruby object from XML using mapping information declared in the class.
      #
      # Accepts a block yielding the currently iterated Definition. If the block returns false
      # the property is skipped.
      #
      # Example:
      #   band.from_xml("<band><name>Nofx</name></band>")
      def from_xml(*args, &block)
        create_represented(*args, &block).from_xml(*args)
      end

      def from_node(*args, &block)
        create_represented(*args, &block).from_node(*args)
      end

    private
      def representer_engine
        Representable::XML
      end
    end

    def remove_namespaces?
      representable_attrs.remove_namespaces
    end

    def from_xml(doc, *args)
      node = remove_namespaces? ?
        Nokogiri::XML(doc).remove_namespaces!.root :
        Nokogiri::XML(doc).root
      from_node(node, *args)
    end

    def from_node(node, options={})
      update_properties_from(node, options, PropertyBinding)
    end

    # Returns a Nokogiri::XML object representing this object.
    def to_node(options={})
      root_tag = options[:wrap] || representation_wrap

      create_representation_with(Nokogiri::XML::Node.new(root_tag.to_s, Nokogiri::XML::Document.new), options, PropertyBinding)
    end

    def to_xml(*args)
      to_node(*args).to_s
    end
  end
end
