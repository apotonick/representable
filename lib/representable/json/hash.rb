require 'representable/hash_methods'

module Representable::JSON
  module Hash
    include Representable::JSON
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
      [:_self, { :hash => true, :use_attributes => true }]
    end
  end
end
