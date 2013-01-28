module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    attr_reader :name, :options
    alias_method :getter, :name
    
    def initialize(sym, options={})
      @name     = sym.to_s
      @options  = options
      
      @options[:default] ||= [] if array?  # FIXME: move to CollectionBinding!
    end
    
    def clone
      self.class.new(name, options.clone) # DISCUSS: make generic Definition.cloned_attribute that passes list to constructor.
    end

    def setter
      :"#{name}="
    end
    
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
      constantize_option :class
    end
    
    def from
      (options[:from] || name).to_s
    end
    
    def default_for(value)
      return default if skipable_nil_value?(value)
      value
    end
    
    def has_default?
      options.has_key?(:default)
    end
    
    def representer_module
      constantize_option :extend
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

    private
    def constantize_option key
      if options[key].is_a? String
        options[key] = constantize_string(options[key])
      end

      options[key]
    end

    # Adapted from ActiveSupport::Inflector#constantize 3.2.11
    # activesupport/lib/active_support/inflector/methods.rb line 193
    # https://github.com/rails/rails/blob/3-2-stable/activesupport/lib/active_support/inflector/methods.rb
    #
    # Ruby 1.9 introduces an inherit argument for Module#const_get and
    # #const_defined? and changes their default behavior.
    if Module.method(:const_get).arity == 1
      # Tries to find a constant with the name specified in the argument string:
      #
      #   constantize_string 'Module'     # => Module
      #   constantize_string 'Test::Unit' # => Test::Unit
      #
      # The name is assumed to be the one of a top-level constant, no matter whether
      # it starts with "::" or not. No lexical context is taken into account:
      #
      #   C = 'outside'
      #   module M
      #     C = 'inside'
      #     C               # => 'inside'
      #     constantize_string "C" # => 'outside', same as ::C
      #   end
      #
      # NameError is raised when the name is not in CamelCase or the constant is
      # unknown.
      def constantize_string(camel_cased_word)
        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
          constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
        constant
      end
    else
      def constantize_string(camel_cased_word) #:nodoc:
        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
          constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
        end
        constant
      end
    end
  end
end
