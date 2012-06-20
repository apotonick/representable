require "virtus"

module Representable::Coercion
  def self.included(base)
    base.class_eval do
      include Virtus
      extend ClassMethods
    end
  end

  module ClassMethods
    def property(name, args={})
       attribute(name, args[:type]) if args[:type] # FIXME (in virtus): undefined method `superclass' for VirtusCoercionTest::SongRepresenter:Module
      super(name, args)
    end
  end
end
