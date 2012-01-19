require 'representable/definition'

# Representable can be used in two ways.
#
# == On class level
#
# To try out Representable you might include the format module into the represented class directly and then
# define the properties.
#
#   class Hero < ActiveRecord::Base
#     include Representable::JSON
#     property :name
#
# This will give you to_/from_json for each instance. However, this approach limits your class to one representation.
#
# == On module level
#
# Modules give you much more flexibility since you can mix them into objects at runtime, roughly following the DCI
# pattern.
#
#   module HeroRepresenter
#     include Representable::JSON
#     property :name
#   end
#
#   hero.extend(HeroRepresenter).to_json
module Representable
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      extend ClassMethods::Declarations
      extend ClassMethods::Accessors
      
      def self.included(base)
        base.representable_attrs.push(*representable_attrs) # "inherit".
      end
      
      # Copies the representable_attrs to the extended object.
      def self.extended(object)
        attrs = representable_attrs
        object.instance_eval do
          @representable_attrs = attrs
        end
      end
    end
  end
  
  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc, options, format, &block)
    representable_bindings_for(format).each do |bin|
      next if skip_property?(bin, options)
      
      value = bin.read(doc) || bin.definition.default
      send(bin.definition.setter, value)
    end
    self
  end
  
private
  # Compiles the document going through all properties.
  def create_representation_with(doc, options, format, &block)
    representable_bindings_for(format).each do |bin|
      next if skip_property?(bin, options)
      
      value = send(bin.definition.getter) || bin.definition.default # DISCUSS: eventually move back to Ref.
      bin.write(doc, value) if value || bin.definition.include_nil
    end
    doc
  end
  
  # Checks and returns if the property should be included.
  def skip_property?(binding, options)
    return unless props = options[:except] || options[:include]
    res = props.include?(binding.definition.name.to_sym)
    options[:include] ? !res : res
  end
  
  def representable_attrs
    @representable_attrs ||= self.class.representable_attrs # DISCUSS: copy, or better not?
  end
  
  def representable_bindings_for(format)
    representable_attrs.map {|attr| format.binding_for_definition(attr) }
  end
  
  # Returns the wrapper for the representation. Mostly used in XML.
  def representation_wrap
    representable_attrs.wrap_for(self.class.name)
  end
  
  
  module ClassMethods # :nodoc:
    # Create and yield object and options. Called in .from_json and friends. 
    def create_represented(document, *args)
      new.tap do |represented|
        yield represented, *args if block_given?
      end
    end
    
    module Declarations
      def definition_class
        Definition
      end
      
      # Declares a represented document node, which is usually a XML tag or a JSON key.
      #
      # Examples:
      #
      #   property :name
      #   property :name, :from => :title
      #   property :name, :class => Name
      #   property :name, :default => "Mike"
      #   property :name, :include_nil => true
      def property(name, options={})
        representable_attrs << definition_class.new(name, options)
      end
      
      # Declares a represented document node collection.
      #
      # Examples:
      #
      #   collection :products
      #   collection :products, :from => :item
      #   collection :products, :class => Product
      def collection(name, options={})
        options[:collection] = true
        property(name, options)
      end
    end
    
    
    module Accessors
      def representable_attrs
        @representable_attrs ||= Config.new
      end
      
      def representation_wrap=(name)
        representable_attrs.wrap = name
      end
    end
  end
  
  
  class Config < Array
    attr_accessor :wrap
    
    # Computes the wrap string or returns false.
    def wrap_for(name)
      return unless wrap
      return infer_name_for(name) if wrap === true
      wrap
    end
    
  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
  
  
  # Allows mapping formats to representer classes.
  # DISCUSS: this module might be removed soon.
  module Represents
    def represents(format, options)
      representer[format] = options[:with]
    end
    
    def representer
      @represents_map ||= {}
    end
  end
end
