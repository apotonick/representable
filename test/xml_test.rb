require 'test_helper'
require 'representable/xml'

class Band
  include Representable::XML
  representable_property :name
  
  def initialize(name=nil)
    name and self.name = name
  end
end

class Label
  def to_node
    "<label>Fat Wreck</label>"
  end
end
  
  
class XmlTest < MiniTest::Spec
  XML = Representable::XML
  Def = Representable::Definition
  
  describe "Xml module" do
    before do
      @Band = Class.new do
        include Representable::XML
        self.representation_wrap = :band
        representable_property :name
        representable_property :label
      end
      
      @Link = Class.new do
        include Representable::XML
        representable_property :href,   :from => "@href"
        representable_property :title,  :from => "@title"
      end
    end
    
    
    describe "#binding_for_definition" do
      it "returns AttributeBinding" do
        assert_kind_of XML::AttributeBinding, @Link.binding_for_definition(Def.new(:band, :from => "@band"))
      end
      
      it "returns ObjectBinding" do
        assert_kind_of XML::ObjectBinding, @Link.binding_for_definition(Def.new(:band, :as => Hash))
      end
      
      it "returns TextBinding" do
        assert_kind_of XML::TextBinding, @Link.binding_for_definition(Def.new(:band, :from => :content))
      end
    end
    
    
    describe "#to_xml" do
      it "wraps with infered class name per default" do
        assert_xml_equal "<band><name>Rise Against</name></band>", Band.new("Rise Against").to_xml
      end
      
      it "respects #representation_wrap=" do
        klass = Class.new(Band)
        klass.representation_wrap = :group
        assert_xml_equal "<group><name>Rise Against</name></group>", klass.new("Rise Against").to_xml
      end
    end
    
    
    describe "#from_xml" do
      before do
        @band = @Band.new
      end
      
      it "accepts xml string" do
        @band.from_xml(%{<band><name>Nofx</name><label>NOFX</label></band>})
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
      end
      
      it "forwards block to #update_properties_from" do
        @band.from_xml(%{<band><name>Nofx</name><label>NOFX</label></band>}) do |binding|
          binding.definition.name == "name"
        end
        
        assert_equal ["Nofx", nil], [@band.name, @band.label]
      end
    end
    
    describe ".from_xml" do
      it "passes all args to #from_xml" do
        block = lambda {|bind|}
        @Band.any_instance.expects(:from_xml).with("{}") # FIXME: how to expect block?
        @Band.from_xml("{}", &block)
      end
    end
    
  end
end

class AttributesTest < MiniTest::Spec
  describe ":from => @rel" do
    class Link
      include Representable::XML
      representable_property :href,   :from => "@href"
      representable_property :title,  :from => "@title"
    end
    
    it "#from_xml creates correct accessors" do
      link = Link.from_xml(%{
        <a href="http://apotomo.de" title="Home, sweet home" />
      })
      assert_equal "http://apotomo.de", link.href
      assert_equal "Home, sweet home",  link.title
    end
  
    it "#to_xml serializes correctly" do
      link = Link.new
      link.href = "http://apotomo.de/"
      
      assert_xml_equal %{<link href="http://apotomo.de/">}, link.to_xml
    end
  end
end

class TypedPropertyTest < MiniTest::Spec
  describe ":as => Item" do
    class Album
      include Representable::XML
      representable_property :band, :as => Band
      representable_property :label, :as => Label
    end
    
    it "#from_xml creates one Item instance" do
      album = Album.from_xml(%{
        <album>
          <band><name>Bad Religion</name></band>
        </album>
      })
      assert_equal "Bad Religion", album.band.name
    end
    
    describe "#to_xml" do
      it "doesn't escape xml from Band#to_xml" do
        band = Band.new
        band.name = "Bad Religion"
        album = Album.new
        album.band = band
        
        assert_xml_equal %{<album>
         <band>
           <name>Bad Religion</name>
         </band>
       </album>}, album.to_xml
      end
      
      it "doesn't escape and wrap string from Label#to_xml" do
        album = Album.new
        album.label = Label.new
        
        assert_xml_equal %{<album>
          <label>Fat Wreck</label>
        </album>}, album.to_xml
      end
    end
  end
end


class CollectionTest < MiniTest::Spec
  describe ":as => [Band], :tag => :band" do
    class Compilation
      include Representable::XML
      representable_collection :bands, :as => Band, :from => :band
    end
    
    describe "#representable_collection" do
      it "declares a collection" do
        assert Compilation.representable_attrs.first.array?
      end
    end
    
    
    describe "#from_xml" do
      it "pushes collection items to array" do
        cd = Compilation.from_xml(%{
          <compilation>
            <band><name>Diesel Boy</name></band>
            <band><name>Cobra Skulls</name></band>
          </compilation>
        })
        assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
      end
      
      it "collections can be empty" do
        cd = Compilation.from_xml(%{
          <compilation>
          </compilation>
        })
        assert_equal [], cd.bands
      end
    end
    
    it "responds to #to_xml" do
      cd = Compilation.new
      cd.bands = [Band.new("Diesel Boy"), Band.new("Bad Religion")]
      
      assert_xml_equal %{<compilation>
        <band><name>Diesel Boy</name></band>
        <band><name>Bad Religion</name></band>
      </compilation>}, cd.to_xml.to_s
    end
  end
    
    
  describe ":as => []" do
    class Album
      include Representable::XML
      representable_collection :songs, :from => :song
    end

    it "collects untyped items" do
      album = Album.from_xml(%{
        <album>
          <song>Two Kevins</song>
          <song>Wright and Rong</song>
          <song>Laundry Basket</song>
        </album>
      })
      assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
    end
  end
end
