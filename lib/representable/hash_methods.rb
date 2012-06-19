module Representable
  module HashMethods
    # FIXME: refactor Definition so we can simply add options in #items to existing definition.
    def representable_attrs
      attrs = super
      attrs << Definition.new(*definition_opts) if attrs.size == 0
      attrs
    end

    def create_representation_with(doc, options, format)
      bin   = representable_bindings_for(format).first
      hash  = filter_keys_for(self, options)
      bin.write(doc, hash)
    end

    def update_properties_from(doc, options, format)
      bin   = representable_bindings_for(format).first
      hash  = filter_keys_for(doc, options)
      value = bin.deserialize_from(hash)
      replace(value)
      self
    end

  private
    def filter_keys_for(hash, options)
      return hash unless props = options[:exclude] || options[:include]
      hash.reject { |k,v| options[:exclude] ? props.include?(k.to_sym) : !props.include?(k.to_sym) }
    end
  end
end
