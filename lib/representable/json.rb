require 'representable/hash'
require 'multi_json'

module Representable
  # Brings #to_json and #from_json to your object.
  module JSON
    extend Hash::ClassMethods
    include Hash

    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
        extend Representable::Hash::ClassMethods  # DISCUSS: this is only for .from_hash, remove in 2.3?
      end
    end
    
    
    module ClassMethods
      # Creates a new object from the passed JSON document.
      def from_json(*args, &block)
        create_represented(*args, &block).from_json(*args)
      end
    end
    
    
    # Parses the body as JSON and delegates to #from_hash.
    def from_json(data, *args)
      data = ::JSON[data]
      from_hash(data, *args)
    end
    
    # Returns a JSON string representing this object.
    def to_json(*args)
      to_hash(*args).to_json
    end
  end
end
