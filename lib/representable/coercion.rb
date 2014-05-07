require "virtus"

module Representable::Coercion
  class Coercer
    virtus_coercer = Virtus.respond_to?(:model) ? Virtus.model : Virtus
    include virtus_coercer

    def coerce(name, v) # TODO: test me.
      # set and get the value as i don't know where exactly coercion happens in virtus.
      send("#{name}=", v)
      send(name)
    end
  end
  # separate coercion object doesn't give us initializer and accessors in the represented object (with module representer)!

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      # FIXME: use inheritable_attr when it's ready.
      representable_attrs.inheritable_array(:coercer_class) << Class.new(Coercer) unless representable_attrs.inheritable_array(:coercer_class).first
    end

  end

  module ClassMethods
    def property(name, options={})
      return super unless options[:type]

      representable_attrs.inheritable_array(:coercer_class).first.attribute(name, options[:type])

      # By using :getter we "pre-occupy" this directive, but we avoid creating accessors, which i find is the cleaner way.
      options[:exec_context] = :decorator
      options[:getter] = lambda { |*| coercer.coerce(name, represented.send(name)) }
      options[:setter] = lambda { |v,*| represented.send("#{name}=", coercer.coerce(name, v)) }

      super
    end
  end

  def coercer
    @coercer ||= representable_attrs.inheritable_array(:coercer_class).first.new
  end
end
