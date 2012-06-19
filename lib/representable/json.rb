require 'representable'
require 'representable/bindings/json_bindings'
require 'json'

module Representable
  # Brings #to_xml, #to_hash, #from_xml and #from_hash to your object.
  #
  # Note: The authorative methods are #to_hash and #from_hash, if you override #to_json instead,
  # things might work as expected.
  module JSON
    def self.binding_for_definition(definition)
      return CollectionBinding.new(definition)  if definition.array?
      return HashBinding.new(definition)        if definition.hash?
      PropertyBinding.new(definition)
    end

    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
      end
    end


    module ClassMethods
      # Creates a new object from the passed JSON document.
      def from_json(*args, &block)
        create_represented(*args, &block).from_json(*args)
      end

      def from_hash(*args, &block)
        create_represented(*args, &block).from_hash(*args)
      end
    end


    # Parses the body as JSON and delegates to #from_hash.
    def from_json(data, *args)
      data = ::JSON[data]
      from_hash(data, *args)
    end

    def from_hash(data, options={})
      if wrap = options[:wrap] || representation_wrap
        data = data[wrap.to_s]
      end

      update_properties_from(data, options, JSON)
    end

    def to_hash(options={})
      hash = create_representation_with({}, options, JSON)

      return hash unless wrap = options[:wrap] || representation_wrap

      {wrap => hash}
    end

    # Returns a JSON string representing this object.
    def to_json(*args)
      to_hash(*args).to_json
    end
  end
end
