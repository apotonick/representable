class Object
  def public_send(meth_name, *args)
    if self.public_methods.include?(meth_name)
      send(meth_name, *args)
    else
      raise NoMethodError, "private method `#{meth_name}' called for #{self.inspect}"
    end
  end
end
