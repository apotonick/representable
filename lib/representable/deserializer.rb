module Representable
  class CollectionDeserializer < Array # always is the targeted collection, already.
    def initialize(binding) # TODO: get rid of binding dependency
      # next step: use #get always.
      @binding = binding
      collection = []
      # should be call to #default:
      collection = binding.get if binding.sync?

      super collection
    end

    def deserialize(fragment)
      # next step: get rid of collect.
      fragment.enum_for(:each_with_index).collect { |item_fragment, i|
        @deserializer = ObjectDeserializer.new(@binding, lambda { self[i] })

        @deserializer.call(item_fragment) # FIXME: what if obj nil?
      }
    end
  end


  class ObjectDeserializer
    # dependencies: Def#options, Def#create_object, Def#get
    def initialize(binding, object)
      @binding = binding
      @object  = object
    end

    def call(fragment)
      # TODO: this used to be handled in #serialize where Object added it's behaviour. treat scalars as objects to remove this switch:
      return fragment unless @binding.typed?

      # If syncing, get the existing object (Binding#get or Binding#get[i]),
      # If not syncing (or if the existing object is nil) create a new object.
      @object = (@object.call if @binding.sync?) || @binding.create_object(fragment)

      # DISCUSS: what parts should be in this class, what in Binding?
      representable = prepare(@object)
      deserialize(representable, fragment, @binding.user_options)
      #yield @object
    end

  private
    def deserialize(object, fragment, options)
      object.send(@binding.deserialize_method, fragment, options)
    end

    def prepare(object)
      mod = @binding.representer_module_for(object)

      return object unless mod

      mod = mod.first if mod.is_a?(Array) # TODO: deprecate :extend => [..]
      mod.prepare(object)
    end
    # in deserialize, we should get the original object?
  end
end