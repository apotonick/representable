module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    attr_reader :name, :options
    
    def initialize(sym, options={})
      @name     = sym.to_s
      @options  = options
      
      @options[:default] ||= [] if array?  # FIXME: move to CollectionBinding!
    end
    
    def clone
      self.class.new(@name, options.clone) # DISCUSS: make generic Definition.cloned_attribute that passes list to constructor.
    end

    def setter
      :"#{name}="
    end
    
    def name
      (options[:name] || @name).to_s
    end
    alias_method :getter, :name

    def typed?
      sought_type.is_a?(Class) or representer_module or options[:instance]  # also true if only :extend is set, for people who want solely rendering.
    end
    
    def array?
      options[:collection]
    end
    
    def hash?
      options[:hash]
    end
    
    def sought_type
      options[:class]
    end
    
    def from
      (options[:from] || @name).to_s
    end
    
    def default_for(value)
      return default if skipable_nil_value?(value)
      value
    end
    
    def has_default?
      options.has_key?(:default)
    end
    
    def representer_module
      options[:extend]
    end
    
    def attribute
      options[:attribute]
    end
    
    def skipable_nil_value?(value)
      value.nil? and not options[:render_nil]
    end
    
    def default
      options[:default]
    end
  end
end
