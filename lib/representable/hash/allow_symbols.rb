# frozen_string_literal: true

module Representable::Hash
  module AllowSymbols
    private

    def filter_wrap_for(data, *args)
      super(Conversion.stringify_keys(data), *args)
    end

    def update_properties_from(data, *args)
      super(Conversion.stringify_keys(data), *args)
    end
  end
end
