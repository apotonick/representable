require 'representable/hash_methods'

module Representable::XML
  module AttributeHash
    include Representable::XML
    include Representable::HashMethods

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end


    module ClassMethods
      def values(options)
        hash :_self, options.merge!(:use_attributes => true)
      end
    end


    def definition_opts
      [:_self, { :hash => true, :use_attributes => true }]
    end
  end

  module Hash
    include Representable::XML
    include HashMethods

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end


    module ClassMethods
      def values(options)
        hash :_self, options
      end
    end


   def definition_opts
      [:_self, { :hash => true }]
    end
  end
end
