module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    attr_reader :name, :sought_type, :from, :default, :representer_module, :attribute,
                :include_nil
    alias_method :getter, :name
    
    def initialize(sym, options={})
      @name               = sym.to_s
      @array              = options[:collection]
      @from               = (options[:from] || name).to_s
      @sought_type        = options[:class]
      @default            = options[:default]
      @default            ||= [] if array?
      @representer_module = options[:extend]  # DISCUSS: move to Representable::DCI?
      @attribute          = options[:attribute] 
      @include_nil        = options[:include_nil]
    end

    def instance_variable_name
      :"@#{name}"
    end

    def setter
      :"#{name}="
    end
    
    def typed?
      sought_type.is_a?(Class) or representer_module  # also true if only :extend is set, for people who want solely rendering.
    end
    
    def array?
      @array
    end
    
    # Applies the block to +value+ which might also be a collection.
    def apply(value)
      return value unless value # DISCUSS: is that ok here?
      
      if array?
        value = value.collect do |item|
          yield item
        end
      else
        value = yield value
      end
      
      value
    end
  end
end
