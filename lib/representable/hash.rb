require 'representable'
require 'representable/bindings/hash_bindings'

module Representable
  # The generic representer. Brings #to_hash and #from_hash to your object.
  # If you plan to write your own representer for a new media type, try to use this module (e.g., check how JSON reuses Hash's internal
  # architecture).
  module Hash
    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
      end
    end


    module ClassMethods
      def from_hash(*args, &block)
        create_represented(*args, &block).from_hash(*args)
      end

    private
      def representer_engine
        Representable::Hash
      end
    end


    def from_hash(data, options={}, binding_builder=PropertyBinding)
      if wrap = options[:wrap] || representation_wrap
        data = data[wrap.to_s]
      end

      convert_keys_to_string(data)

      update_properties_from(data, options, binding_builder)
    end

    def to_hash(options={}, binding_builder=PropertyBinding)
      hash = create_representation_with({}, options, binding_builder)

      return hash unless wrap = options[:wrap] || representation_wrap

      {wrap => hash}
    end

    private

    def convert_keys_to_string(hash)
      hash.tap do |h|
        h.keys.each { |k| h[k.to_s] = h.delete(k) }
      end
    end
  end
end
