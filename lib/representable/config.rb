module Representable
  # NOTE: the API of Config is subject to change so don't rely too much on this private object.
  class Config < Hash
    # DISCUSS: experimental. this will soon be moved to a separate gem
    module InheritableArray
      def inheritable_array(name)
        inheritable_arrays[name] ||= []
      end
      def inheritable_arrays
        @inheritable_arrays ||= {}
      end

      def inherit(parent)
        super

        parent.inheritable_arrays.keys.each do |k|
          inheritable_array(k).push *parent.inheritable_array(k).clone
        end
      end
    end

    def <<(definition)
      self[definition.name] = definition
    end

    def [](name)
      fetch(name.to_s, nil)
    end

    def each(*args, &block)
      values.each(*args, &block)
    end

    attr_accessor :wrap
    attr_accessor :remove_namespaces

    # Computes the wrap string or returns false.
    def wrap_for(name)
      return unless wrap
      return infer_name_for(name) if wrap === true
      wrap
    end

    module InheritMethods
      def cloned
        collect { |d| d.clone }
      end

      def inherit(parent)
        push(parent.cloned)
      end
    end
    include InheritMethods
    include InheritableArray # overrides #inherit.

  private
    def push(defs)
      defs.each { |d| self << d }
    end

    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end