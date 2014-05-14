module Representable::JSON
  module AutoCollection
    def self.included(base)
      base.class_eval do
        include Representable::JSON::Collection
        extend ClassMethods
      end
    end

    module ClassMethods
      def items(options, &block)
        options[:extend] = Module.new do
          include Representable::JSON
          instance_exec &block
        end
        collection :_self, options
      end
    end
  end
end
