require 'test_helper'

class RepresentableTest < MiniTest::Spec
  class Band
    include Representable
    property :name
    attr_accessor :name
  end
  
  class PunkBand < Band
    property :street_cred
    attr_accessor :street_cred
  end
  
  module BandRepresentation
    include Representable
    
    property :name
  end
  
  module PunkBandRepresentation
    include Representable
    include BandRepresentation
    
    property :street_cred
  end
  
  
  describe "#representable_attrs" do
    it "responds to #representable_attrs" do
      assert_equal 1, Band.representable_attrs.size
      assert_equal "name", Band.representable_attrs.first.name
    end
    
    describe "in module" do
      it "returns definitions" do
        assert_equal 1, BandRepresentation.representable_attrs.size
        assert_equal "name", BandRepresentation.representable_attrs.first.name
      end
      
      it "inherits to including modules" do
        assert_equal 2,  PunkBandRepresentation.representable_attrs.size
        assert_equal "name", PunkBandRepresentation.representable_attrs.first.name
        assert_equal "street_cred", PunkBandRepresentation.representable_attrs.last.name
      end
      
      it "inherits to including class" do
        band = Class.new do
          include Representable
          include PunkBandRepresentation
        end
        
        assert_equal 2,  band.representable_attrs.size
        assert_equal "name", band.representable_attrs.first.name
        assert_equal "street_cred", band.representable_attrs.last.name
      end
      
      it "allows including the concrete representer module later" do
        vd = class VD
          attr_accessor :name, :street_cred
          include Representable::JSON
          include PunkBandRepresentation
        end.new
        vd.name        = "Vention Dention"
        vd.street_cred = 1
        assert_equal "{\"name\":\"Vention Dention\",\"street_cred\":1}", vd.to_json
      end
      
      #it "allows including the concrete representer module only" do
      #  require 'representable/json'
      #  module RockBandRepresentation
      #    include Representable::JSON
      #    property :name
      #  end
      #  vd = class VH
      #    include RockBandRepresentation
      #  end.new
      #  vd.name        = "Van Halen"
      #  assert_equal "{\"name\":\"Van Halen\"}", vd.to_json
      #end
      
      it "doesn't share inherited properties between family members" do
        parent = Module.new do
          include Representable
          property :id
        end
        
        child = Module.new do
          include Representable
          include parent
        end
        
        assert parent.representable_attrs.first != child.representable_attrs.first, "definitions shouldn't be identical"
      end
      
    end
  end
  
  
  describe "Representable" do
    it "allows mixing in multiple representers" do
      require 'representable/json'
      require 'representable/xml'
      class Bodyjar
        include Representable::XML
        include Representable::JSON
        include PunkBandRepresentation
        
        self.representation_wrap = "band"
        attr_accessor :name, :street_cred
      end
      
      band = Bodyjar.new
      band.name = "Bodyjar"
      
      assert_equal "{\"band\":{\"name\":\"Bodyjar\"}}", band.to_json
      assert_xml_equal "<band><name>Bodyjar</name></band>", band.to_xml
    end
    
    it "allows extending with different representers subsequentially" do
      module SongXmlRepresenter
        include Representable::XML
        property :name, :from => "name", :attribute => true
      end
      
      module SongJsonRepresenter
        include Representable::JSON
        property :name
      end
      
      @song = Song.new("Days Go By")
      assert_xml_equal "<song name=\"Days Go By\"/>", @song.extend(SongXmlRepresenter).to_xml
      assert_equal "{\"name\":\"Days Go By\"}", @song.extend(SongJsonRepresenter).to_json
    end
  end
  
  
  describe "#property" do
    it "creates accessors for the attribute" do
      @band = PunkBand.new
      assert @band.name = "Bad Religion"
      assert_equal "Bad Religion", @band.name
    end
    
    describe ":from" do
      # TODO: do this with all options.
      it "can be set explicitly" do
        band = Class.new(Band) { property :friends, :from => :friend }
        assert_equal "friend", band.representable_attrs.last.from
      end
      
      it "is infered from the name implicitly" do
        band = Class.new(Band) { property :friends }
        assert_equal "friends", band.representable_attrs.last.from
      end
    end
    
    describe ":accessor" do
      it "doesn't add methods when false" do
        klass = Class.new(Band) { property :friends, :accessors => false }
        band = klass.new
        assert ! band.respond_to?(:friends)
        assert ! band.respond_to?("friends=")
      end
    end
  end
  
  describe "#collection" do
    class RockBand < Band
      collection :albums
    end
    
    it "creates correct Definition" do
      assert_equal "albums", RockBand.representable_attrs.last.name
      assert RockBand.representable_attrs.last.array?
    end
  end
  
  describe "#hash" do
    it "also responds to the original method" do
      assert_kind_of Integer, BandRepresentation.hash
    end
  end
  
  
  describe "#representation_wrap" do
    class HardcoreBand
      include Representable
    end
  
    class SoftcoreBand < HardcoreBand
    end
    
    before do
      @band = HardcoreBand.new
    end
    
    
    it "returns false per default" do
      assert_equal nil, SoftcoreBand.new.send(:representation_wrap)
    end
    
    it "infers a printable class name if set to true" do
      HardcoreBand.representation_wrap = true
      assert_equal "hardcore_band", @band.send(:representation_wrap)
    end
    
    it "can be set explicitely" do
      HardcoreBand.representation_wrap = "breach"
      assert_equal "breach", @band.send(:representation_wrap)
    end
  end
  
  
  describe "#definition_class" do
    it "returns Definition class" do
      assert_equal Representable::Definition, Band.definition_class
    end
  end

  
  # DISCUSS: i don't like the JSON requirement here, what about some generic test module?
  class PopBand
    include Representable::JSON
    property :name
    property :groupies
    attr_accessor :name, :groupies
  end

  describe "#update_properties_from" do
    before do
      @band = PopBand.new
    end
    
    it "copies values from document to object" do
      @band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}, {}, Representable::JSON)
      assert_equal "No One's Choice", @band.name
      assert_equal 2, @band.groupies
    end
    
    it "accepts :except option" do
      @band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}, {:except => [:groupies]}, Representable::JSON)
      assert_equal "No One's Choice", @band.name
      assert_equal nil, @band.groupies
    end
    
    it "accepts :include option" do
      @band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}, {:include => [:groupies]}, Representable::JSON)
      assert_equal 2, @band.groupies
      assert_equal nil, @band.name
    end
    
    it "always returns self" do
      assert_equal @band, @band.update_properties_from({"name"=>"Nofx"}, {}, Representable::JSON)
    end

    it "allows false attributes" do
      @band.update_properties_from({"groupies"=>false}, {}, Representable::JSON)
      assert_equal false, @band.groupies
    end
  end
  
  describe "#create_representation_with" do
    before do
      @band = PopBand.new
      @band.name = "No One's Choice"
      @band.groupies = 2
    end
    
    it "compiles document from properties in object" do
      assert_equal({"name"=>"No One's Choice", "groupies"=>2}, @band.send(:create_representation_with, {}, {}, Representable::JSON))
    end
    
    it "accepts :except option" do
      hash = @band.send(:create_representation_with, {}, {:except => [:groupies]}, Representable::JSON)
      assert_equal({"name"=>"No One's Choice"}, hash)
    end
    
    it "accepts :include option" do
      hash = @band.send(:create_representation_with, {}, {:include => [:groupies]}, Representable::JSON)
      assert_equal({"groupies"=>2}, hash)
    end

    it "does not write nil attributes" do
      @band.groupies = nil
      assert_equal({"name"=>"No One's Choice"}, @band.send(:create_representation_with, {}, {}, Representable::JSON))
    end

    it "writes false attributes" do
      @band.groupies = false
      assert_equal({"name"=>"No One's Choice","groupies"=>false}, @band.send(:create_representation_with, {}, {}, Representable::JSON))
    end
  end
  
  
  describe "Config" do
    before do
      @config = Representable::Config.new
      PunkRock = Class.new
    end
    
    describe "wrapping" do
      it "returns false per default" do
        assert_equal nil, @config.wrap_for("Punk")
      end
      
      it "infers a printable class name if set to true" do
        @config.wrap = true
        assert_equal "punk_rock", @config.wrap_for(PunkRock)
      end
      
      it "can be set explicitely" do
        @config.wrap = "Descendents"
        assert_equal "Descendents", @config.wrap_for(PunkRock)
      end
    end
    
    describe "clone" do
      it "clones all definitions" do
        @config << Object.new
        assert @config.first != @config.clone.first
      end
    end
  end
  
  describe "Represents" do
    before do
      @class = Class.new do
        extend Representable::Represents
        represents :json, :with => :whatever
        represents "application/order-json", :with => :special
      end
    end
    
    it "allows mapping formats to representers" do
      assert_equal :whatever, @class.representer[:json]
      assert_equal :special, @class.representer["application/order-json"]
    end    
  end
end
