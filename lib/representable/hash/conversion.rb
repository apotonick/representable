# frozen_string_literal: true

module Representable::Hash
  module Conversion
    def stringify_keys(hash)
      mutate_keys(hash, :to_s)
    end

    def symbolize_keys(hash)
      mutate_keys(hash, :to_sym)
    end

    module_function :stringify_keys, :symbolize_keys

    def self.mutate_keys(hash, method)
      hash.each_with_object({}) do |(k, v), new_hash|
        new_hash[k.send(method)] = case v
                                   when Hash
                                     mutate_keys(v, method)
                                   when Array
                                     v.map { |h| h.is_a?(Hash) ? mutate_keys(h, method) : h }
                                   else
                                     v
                                   end
      end
    end
  end
end
