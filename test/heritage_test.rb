require "test_helper"

class HeritageTest < Minitest::Spec
  module Hello
    def hello
      puts "Hello!"
    end
  end

  module Ciao
    def ciao
      puts "Ciao!"
    end
  end

  class A < Representable::Decorator
    include Representable::Hash

    feature Hello

    property :id do
    end
  end

  class B < A
    feature Ciao # does NOT extend id, of course.

    property :id, inherit: true do

    end
  end

  class C < A
    property :id do end # overwrite old :id.
  end

  it do
    # puts A.heritage.inspect
    # puts B.heritage.inspect

    puts B.representable_attrs.get(:id)[:extend].(nil).new(nil).hello
    puts B.representable_attrs.get(:id)[:extend].(nil).new(nil).ciao

    # feature Hello must be "inherited" from A and included in new C properties, too.
    puts C.representable_attrs.get(:id)[:extend].(nil).new(nil).hello
  end

  module M
    include Representable
    feature Hello
  end

  module N
    include Representable
    include M
    feature Ciao
  end

  it do
    Object.new.extend(N).hello
  end
end
