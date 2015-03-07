require 'active_support/core_ext/hash/keys.rb'

module Representable
  module Hash
    module SymbolizeKeys
      def to_hash(*args)
        return super.symbolize_keys!
      end
    end
  end
end
