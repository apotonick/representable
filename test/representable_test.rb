require 'test_helper'

class RepresentableTest < MiniTest::Spec
  class Band
    include Representable
    representable_property :name
  end
  
  class PunkBand < Band
    representable_property :street_cred
  end
  
  
  describe "#representable_attrs" do
    it "responds to #representable_attrs" do
      assert_equal 1, Band.representable_attrs.size
      assert_equal "name", Band.representable_attrs.first.name
    end
    
    it "inherits correctly" do
      assert_equal 2, PunkBand.representable_attrs.size
      assert_equal "name", PunkBand.representable_attrs.first.name
      assert_equal "street_cred", PunkBand.representable_attrs.last.name
    end
  end
  
  
  describe "#representable_property" do
    it "creates accessors for the attribute" do
      @band = PunkBand.new
      assert @band.name = "Bad Religion"
      assert_equal "Bad Religion", @band.name
    end
    
    describe ":from" do
      # TODO: do this with all options.
      it "can be set explicitly" do
        band = Class.new(Band) { representable_property :friends, :from => :friend }
        assert_equal "friend", band.representable_attrs.last.from
      end
      
      it "is infered from the name implicitly" do
        band = Class.new(Band) { representable_property :friends }
        assert_equal "friends", band.representable_attrs.last.from
      end
    end
  end
  
  describe "#representable_collection" do
    class RockBand < Band
      representable_collection :albums
    end
    
    it "creates correct Definition" do
      assert_equal "albums", RockBand.representable_attrs.last.name
      assert RockBand.representable_attrs.last.array?
    end
  end
  
  
  describe "#representation_wrap" do
    class SoundSystem
      include Representable
    end
    
    class HardcoreBand
      include Representable
    end
  
    class SoftcoreBand < HardcoreBand
    end
    
    it "returns false per default" do
      assert_equal nil, SoundSystem.representation_wrap
    end
    
    
    it "infers a printable class name if set to true" do
      HardcoreBand.representation_wrap = true
      assert_equal "hardcore_band", HardcoreBand.send(:representation_wrap)
    end
    
    it "can be set explicitely" do
      HardcoreBand.representation_wrap = "breach"
      assert_equal "breach", HardcoreBand.representation_wrap
    end
    
    it "inherits correctly" do
      HardcoreBand.representation_wrap = "breach"
      assert_equal "breach", SoftcoreBand.representation_wrap
    end
  end
  
  
  describe "#definition_class" do
    it "returns Definition class" do
      assert_equal Representable::Definition, Band.definition_class
    end
  end

  
  require 'representable/json'  # DISCUSS: i don't like the JSON requirement here, what about some generic test module?
  class PopBand
    include Representable::JSON
    representable_property :name
    representable_property :groupies
  end

  describe "#update_properties_from" do
    it "copies values from document to object" do
      band = PopBand.new
      band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2})
      assert_equal "No One's Choice", band.name
      assert_equal 2, band.groupies
    end
    
    it "skips elements when block returns false" do
      band = PopBand.new
      band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}) do |binding|
        binding.definition.name == "name"
      end
      assert_equal "No One's Choice", band.name
      assert_equal nil, band.groupies
    end
    
    it "always returns self" do
      band = PopBand.new
      assert_equal band, band.update_properties_from({"name"=>"Nofx"})
    end
  end
  
  describe "#create_representation_with" do
    before do
      @band = PopBand.new
      @band.name = "No One's Choice"
      @band.groupies = 2
    end
    
    it "compiles document from properties in object" do
      assert_equal({"name"=>"No One's Choice", "groupies"=>2}, @band.send(:create_representation_with, {}))
    end
    
    it "skips elements when block returns false" do
      assert_equal({"name"=>"No One's Choice"}, @band.send(:create_representation_with, {}) do |binding| binding.definition.name == "name" end)
    end
  end
  
end
