require 'json'
require 'representable/bindings/json_bindings'

module Representable
  # Brings #to_xml, #to_hash, #from_xml and #from_hash to your object.
  #
  # Note: The authorative methods are #to_hash and #from_hash, if you override #to_json instead,
  # things might work as expected.
  module JSON
    BINDING_FOR_TYPE = {  # TODO: refactor #representable_accessor for better extendability.
      :text     => TextBinding,
    }
    
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end
    
    
    module ClassMethods
      def binding_for_definition(definition)
        (BINDING_FOR_TYPE[definition.sought_type] or ObjectBinding).new(definition)
      end
    
      # Creates a new object from the passed JSON document.
      def from_json(*args, &block)
        new.from_json(*args, &block)
      end
      
      def from_hash(*args, &block)
        new.from_hash(*args, &block)
      end
    end
    
    # Parses the body as JSON and delegates to #from_hash.
    def from_json(data, *args, &block)
      data = ::JSON[data]
      from_hash(data, *args, &block)
    end
    
    def from_hash(data, options={}, &block)
      if wrap = options[:wrap] || self.class.representation_wrap
        data = data[wrap.to_s]
      end
      
      update_properties_from(data, &block)
    end
    
    def to_hash(options={})
      hash = create_representation_with({})
      
      return hash unless wrap = options[:wrap] || self.class.representation_wrap
      
      {wrap => hash}
    end
    
    # Returns a JSON string representing this object.
    def to_json(options={})
      to_hash(options).to_json
    end
  end
end
