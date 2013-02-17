require 'representable/deprecations'
require 'representable/definition'
require 'representable/feature/readable_writeable'

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
# Modules give you much more flexibility since you can mix them into objects at runtime, following the DCI
# pattern.
#
#   module HeroRepresenter
#     include Representable::JSON
#     property :name
#   end
#
#   hero.extend(HeroRepresenter).to_json
module Representable
  attr_writer :representable_attrs

  def self.included(base)
    base.class_eval do
      extend ClassInclusions, ModuleExtensions
      extend ClassMethods
      extend ClassMethods::Declarations

      include Deprecations
      include Feature::ReadableWriteable
    end
  end

  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc, options, format)
    representable_bindings_for(format, options).each do |bin|
      deserialize_property(bin, doc, options)
    end
    self
  end

private
  # Compiles the document going through all properties.
  def create_representation_with(doc, options, format)
    representable_bindings_for(format, options).each do |bin|
      serialize_property(bin, doc, options)
    end
    doc
  end

  def serialize_property(binding, doc, options)
    return if skip_property?(binding, options)
    compile_fragment(binding, doc)
  end

  def deserialize_property(binding, doc, options)
    return if skip_property?(binding, options)
    uncompile_fragment(binding, doc)
  end

  # Checks and returns if the property should be included.
  def skip_property?(binding, options)
    return true if skip_excluded_property?(binding, options)  # no need for further evaluation when :exclude'ed

    skip_conditional_property?(binding)
  end

  def skip_excluded_property?(binding, options)
    return unless props = options[:exclude] || options[:include]
    res   = props.include?(binding.name.to_sym)
    options[:include] ? !res : res
  end

  def skip_conditional_property?(binding)
    # TODO: move to Binding.
    return unless condition = binding.options[:if]

    condition = method(condition) if condition.is_a?(Symbol)

    args = []
    args << binding.user_options if condition.arity > 0 # TODO: remove arity check. users should know whether they pass options or not.

    not instance_exec(*args, &condition)
  end

  # Retrieve value and write fragment to the doc.
  def compile_fragment(bin, doc)
    value = get_for(bin)

    bin.write_fragment(doc, value)
  end

  # Parse value from doc and update the model property.
  def uncompile_fragment(bin, doc)
    bin.read_fragment(doc) do |value|
      set_for(bin, value)
    end
  end

  # TODO: move to Binding.
  def get_for(bin)
    return instance_exec(bin.user_options, &bin.options[:getter]) if bin.options[:getter]
    send(bin.getter)
  end
  def set_for(bin, value)
    value = instance_exec(value, bin.user_options, &bin.options[:setter]) if bin.options[:setter]
    send(bin.setter, value)
  end

  def representable_attrs
    @representable_attrs ||= self.class.representable_attrs # DISCUSS: copy, or better not?
  end

  def representable_bindings_for(format, options)
    options = cleanup_options(options)  # FIXME: make representable-options and user-options two different hashes.
    representable_attrs.map {|attr| format.build(attr, self, options) }
  end

  # Returns the wrapper for the representation. Mostly used in XML.
  def representation_wrap
    representable_attrs.wrap_for(self.class.name)
  end

private
  def cleanup_options(options) # TODO: remove me.
    options.reject { |k,v| [:include, :exclude].include?(k) }
  end

  module ClassInclusions
    def included(base)
      super
      base.representable_attrs.inherit(representable_attrs)
    end
  end

  module ModuleExtensions
    # Copies the representable_attrs to the extended object.
    def extended(object)
      super
      object.representable_attrs=(representable_attrs)
    end
  end


  module ClassMethods
    # Create and yield object and options. Called in .from_json and friends.
    def create_represented(document, *args)
      new.tap do |represented|
        yield represented, *args if block_given?
      end
    end


    module Declarations
      def representable_attrs
        @representable_attrs ||= build_config
      end

      def representation_wrap=(name)
        representable_attrs.wrap = name
      end

      # Declares a represented document node, which is usually a XML tag or a JSON key.
      #
      # Examples:
      #
      #   property :name
      #   property :name, :from => :title
      #   property :name, :class => Name
      #   property :name, :default => "Mike"
      #   property :name, :render_nil => true
      #   property :name, :readable => false
      #   property :name, :writeable => false
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

      def hash(name=nil, options={})
        return super() unless name  # allow Object.hash.

        options[:hash] = true
        property(name, options)
      end

    private
      def definition_class
        Definition
      end

      def build_config
        Config.new
      end
    end
  end


  # NOTE: the API of Config is subject to change so don't rely too much on this private object.
  class Config < Array
    attr_accessor :wrap

    # Computes the wrap string or returns false.
    def wrap_for(name)
      return unless wrap
      return infer_name_for(name) if wrap === true
      wrap
    end

    def clone
      self.class.new(collect { |d| d.clone })
    end

    def inherit(parent)
      push(*parent.clone)
    end

  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end
