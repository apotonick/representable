module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    attr_reader :name, :sought_type, :from
    alias_method :getter, :name
    
    def initialize(sym, options={})
      @name         = sym.to_s
      @array        = options[:collection]
      @from         = (options[:from] || name).to_s
      @sought_type  = options[:as] || :text
      
      # FIXME: move me to xml.
      if options[:from].to_s =~ /^@/
        @sought_type = :attr
        options[:from].sub!('@', '')
      end
    end

    def instance_variable_name
      :"@#{name}"
    end

    def setter
      :"#{name}="
    end
    
    def typed?
      sought_type.is_a?(Class)
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
