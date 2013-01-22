require 'test_helper'

class DefinitionTest < MiniTest::Spec
  describe "generic API" do
    before do
      @def = Representable::Definition.new(:songs)
    end
    
    describe "DCI" do
      it "responds to #representer_module" do
        assert_equal nil, Representable::Definition.new(:song).representer_module
        assert_equal Hash, Representable::Definition.new(:song, :extend => Hash).representer_module
      end
    end
    
    describe "#typed?" do
      it "is false per default" do
        assert ! @def.typed?
      end
      
      it "is true when :class is present" do
        assert Representable::Definition.new(:songs, :class => Hash).typed?
      end
      
      it "is true when :extend is present, only" do
        assert Representable::Definition.new(:songs, :extend => Hash).typed?
      end

      it "is true when :instance is present, only" do
        assert Representable::Definition.new(:songs, :instance => Object.new).typed?
      end
    end
    
    describe '#getter' do
      it "returns the name" do
        assert_equal "songs", @def.getter
      end

      it "returns the new name when :name is redefined" do
        assert_equal "tracks", Representable::Definition.new(:songs, :name => :tracks).getter
      end
    end
    
    describe "#name" do
      it "returns the :name" do
        assert_equal "songs", @def.name
      end

      it "allows redefinition of name" do
        assert_equal "tracks", Representable::Definition.new(:songs, :name => :tracks).name
      end
    end
    
    it "responds to #setter" do
      assert_equal :"songs=", @def.setter
    end
    
    it "responds to #sought_type" do
      assert_equal nil, @def.sought_type
    end

    describe '#from' do
      it 'returns the :from value' do
          assert_equal "tracks", Representable::Definition.new(:songs, :from => :tracks).from
      end

      it 'returns the original @name when :name is redifined' do
          assert_equal "songs", Representable::Definition.new(:songs, :name => :tracks).from
      end

      it 'returns the :from value when :name is redifined' do
          assert_equal "beats", Representable::Definition.new(:beats, :name => :tracks, :from => :beats).from
      end
    end
    
    describe "#clone" do
      it "clones @options" do
        @def.options[:volume] = 9
        cloned = @def.clone
        cloned.options[:volume] = 8
        
        assert_equal @def.options[:volume], 9
        assert_equal cloned.options[:volume], 8
      end
    end
  end
  
  describe "#has_default?" do
    it "returns false if no :default set" do
      assert_equal false, Representable::Definition.new(:song).has_default?
    end
    
    it "returns true if :default set" do
      assert_equal true, Representable::Definition.new(:song, :default => nil).has_default?
    end
    
    it "returns true if :collection" do
      assert_equal true, Representable::Definition.new(:songs, :collection => true).has_default?
    end
    
  end
  
  
  describe "#skipable_nil_value?" do
    # default if skipable_nil_value?
    before do
      @def = Representable::Definition.new(:song, :render_nil => true)
    end
    
    it "returns false when not nil" do
      assert_equal false, @def.skipable_nil_value?("Disconnect, Disconnect")
    end
    
    it "returns false when nil and :render_nil => true" do
      assert_equal false, @def.skipable_nil_value?(nil)
    end
    
    it "returns true when nil and :render_nil => false" do
      assert_equal true, Representable::Definition.new(:song).skipable_nil_value?(nil)
    end
    
    it "returns false when not nil and :render_nil => false" do
      assert_equal false, Representable::Definition.new(:song).skipable_nil_value?("Fatal Flu")
    end
  end
  
  
  describe "#default_for" do
    before do
      @def = Representable::Definition.new(:song, :default => "Insider")
    end
    
    it "always returns value when value not nil" do
      assert_equal "Black And Blue", @def.default_for("Black And Blue")
    end
    
    it "returns false when value false" do
      assert_equal false, @def.default_for(false)
    end
    
    it "returns default when value nil" do
      assert_equal "Insider", @def.default_for(nil)
    end
    
    it "returns nil when value nil and :render_nil true" do
      @def = Representable::Definition.new(:song, :render_nil => true)
      assert_equal nil, @def.default_for(nil)
    end
    
    it "returns nil when value nil and :render_nil true even when :default is set" do
      @def = Representable::Definition.new(:song, :render_nil => true, :default => "The Quest")
      assert_equal nil, @def.default_for(nil)
    end
    
    it "returns nil if no :default" do
      @def = Representable::Definition.new(:song)
      assert_equal nil, @def.default_for(nil)
    end
  end
    
  
  describe "#writeable?" do

    it "returns true when :writeable is not given" do
      @def = Representable::Definition.new(:song)
      assert_equal true, @def.writeable?
    end

    it "returns true when :writeable => true" do
      @def = Representable::Definition.new(:song, :writeable => true)
      assert_equal true, @def.writeable?
    end

    it "returns false when :writeable => false" do
      @def = Representable::Definition.new(:song, :writeable => false)
      assert_equal false, @def.writeable?
    end

    it "returns nil when :writeable is nil" do
      @def = Representable::Definition.new(:song, :writeable => nil)
      assert_equal nil, @def.writeable?
    end
    
  end

  describe "#readable?" do

    it "returns true when :readable is not given" do
      @def = Representable::Definition.new(:song)
      assert_equal true, @def.readable?
    end

    it "returns true when :readable => true" do
      @def = Representable::Definition.new(:song, :readable => true)
      assert_equal true, @def.readable?
    end

    it "returns false when :readable => false" do
      @def = Representable::Definition.new(:song, :readable => false)
      assert_equal false, @def.readable?
    end

    it "returns nil when :readable is nil" do
      @def = Representable::Definition.new(:song, :readable => nil)
      assert_equal nil, @def.readable?
    end

  end


  describe ":collection => true" do
    before do
      @def = Representable::Definition.new(:songs, :collection => true, :tag => :song)
    end
    
    it "responds to #array?" do
      assert @def.array?
    end
    
    it "responds to #sought_type" do
      assert_equal nil, @def.sought_type
    end
    
    it "responds to #default" do
      assert_equal [], @def.send(:default)
    end
  end
  
  describe ":class => Item" do
    before do
      @def = Representable::Definition.new(:songs, :class => Hash)
    end
    
    it "responds to #sought_type" do
      assert_equal Hash, @def.sought_type
    end
  end
  
  describe ":default => value" do
    it "responds to #default" do
      @def = Representable::Definition.new(:song)
      assert_equal nil, @def.send(:default)
    end
    
    it "accepts a default value" do
      @def = Representable::Definition.new(:song, :default => "Atheist Peace")
      assert_equal "Atheist Peace", @def.send(:default)
    end
  end
  
  describe ":hash => true" do
    before do
      @def = Representable::Definition.new(:songs, :hash => true)
    end
    
    it "responds to #hash?" do
      assert @def.hash?
      assert ! Representable::Definition.new(:songs).hash?
    end
  end
end
