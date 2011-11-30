require 'hooks/inheritable_attribute'
require 'representable/definition'
require 'representable/nokogiri_extensions'


module Representable
  def self.included(base)
    base.class_eval do
      extend ClassMethods::Declarations
      extend ClassMethods::Accessors
      
      extend Hooks::InheritableAttribute
      inheritable_attr :representable_attrs
      self.representable_attrs = []
      
      inheritable_attr :representable_wrap
    end
  end
  
  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc)
    self.class.representable_bindings.each do |ref|
      next if block_given? and not yield ref # skip if block is false. # DISCUSS: will we keep that?
      
      value = ref.read(doc)
      send(ref.definition.setter, value)
    end
    self
  end
  
private
  # Compiles the document going through all properties.
  def create_representation_with(doc)
    self.class.representable_bindings.each do |ref|
      next if block_given? and not yield ref # skip if block is false. # DISCUSS: will we keep that?
      
      value = public_send(ref.definition.getter) # DISCUSS: eventually move back to Ref.
      ref.write(doc, value) if value
    end
    doc
  end
  
  
  module ClassMethods # :nodoc:
    module Declarations
      def definition_class
        Definition
      end
      
      # Returns bindings for all properties.
      def representable_bindings
        representable_attrs.map {|attr| binding_for_definition(attr) }
      end
      
      # Declares a represented document node, which is usually a XML tag or a JSON key.
      #
      # Examples:
      #
      #   representable_property :name
      #   representable_property :name, :from => :title
      #   representable_property :name, :as => Name
      def representable_property(*args)
        attr = add_representable_property(*args)
        attr_reader(attr.getter)
        attr_writer(attr.getter)
      end
      
      # Declares a represented document node collection.
      #
      # Examples:
      #
      #   representable_collection :products
      #   representable_collection :products, :from => :item
      #   representable_collection :products, :as => Product
      def representable_collection(name, options={})
        options[:collection] = true
        representable_property(name, options)
      end
      
    private
      def add_representable_property(*args)
        definition_class.new(*args).tap do |attr|
          representable_attrs << attr
        end
      end
    end

    module Accessors
      def representation_wrap=(name)
        self.representable_wrap = name
      end
      
      # Returns the wrapper for the representation. Mostly used in XML.
      def representation_wrap
        return unless representable_wrap
        return infer_representation_name if representable_wrap === true
        representable_wrap
      end
      
    private
      def infer_representation_name
        name.split('::').last.
         gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         downcase
      end
    end
  end
end
