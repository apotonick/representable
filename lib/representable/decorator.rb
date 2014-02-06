module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    def self.prepare(represented)
      new(represented)
    end

    def self.superclass_for_inline_representer(name, options)
      # look for existing representable attribute with given name
      attr = representable_attrs[name]

      superclass = attr.representer_module if attr && options[:inherit]
      superclass ||= self
    end

    def self.inline_representer(base_module, name, options, &block) # DISCUSS: separate module?
      superclass = superclass_for_inline_representer(name, options)

      Class.new(superclass) do
        include base_module
        instance_exec &block
      end
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    def initialize(represented)
      @represented = represented
    end
  end
end
