require 'test_helper'
require 'representable/xml'

class Band
  include Representable::XML
  representable_property :name
  
  def initialize(name=nil)
    name and self.name = name
  end
end

class Album
  include Representable::XML
  representable_property :band, :as => Band
  
  def initialize(band=nil)
    band and self.band = band
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
    end
    
    
    describe ".from_xml" do
      it "is delegated to #from_xml" do
        block = lambda {|bind|}
        @Band.any_instance.expects(:from_xml).with("{}", "yo") # FIXME: how to expect block?
        @Band.from_xml("{}", "yo", &block)
      end
    end
    
    
    describe ".from_node" do
      it "is delegated to #from_node" do
        block = lambda {|bind|}
        @Band.any_instance.expects(:from_node).with("{}", "yo") # FIXME: how to expect block?
        @Band.from_node("{}", "yo", &block)
      end
    end
    
    
    describe "#from_xml" do
      before do
        @band = @Band.new
        @xml  = %{<band><name>Nofx</name><label>NOFX</label></band>}
      end
      
      it "parses XML and assigns properties" do
        @band.from_xml(@xml)
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
      end
      
      it "forwards block to #from_node" do
        @band.from_xml(@xml) do |name|
          name == :name
        end
        
        assert_equal ["Nofx", nil], [@band.name, @band.label]
      end
    end
    
    
    describe "#from_node" do
      before do
        @band = @Band.new
        @xml  = Nokogiri::XML(%{<band><name>Nofx</name><label>NOFX</label></band>}).root
      end
      
      it "receives Nokogiri node and assigns properties" do
        @band.from_node(@xml)
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
      end
      
      it "forwards block to #update_properties_from" do
        @band.from_node(@xml) do |name|
          name == :name
        end
        
        assert_equal ["Nofx", nil], [@band.name, @band.label]
      end
    end
    
    describe "#to_xml" do
      it "delegates to #to_node and returns string" do
        assert_xml_equal "<band><name>Rise Against</name></band>", Band.new("Rise Against").to_xml
      end
      
      it "forwards block to #to_node" do
        band = @Band.new
        band.name  = "The Guinea Pigs"
        band.label = "n/a"
        xml = band.to_xml do |name|
          name == :name
        end
        
        assert_xml_equal "<band><name>The Guinea Pigs</name></band>", xml
      end
    end
    
    
    describe "#to_node" do
      it "returns Nokogiri node" do
        node = Band.new("Rise Against").to_node
        assert_kind_of Nokogiri::XML::Element, node
      end
      
      it "wraps with infered class name per default" do
        node = Band.new("Rise Against").to_node
        assert_xml_equal "<band><name>Rise Against</name></band>", node.to_s 
      end
      
      it "respects #representation_wrap=" do
        klass = Class.new(Band)
        klass.representation_wrap = :group
        assert_xml_equal "<group><name>Rise Against</name></group>", klass.new("Rise Against").to_node.to_s
      end
    end
    
    
    describe "#binding_for_definition" do
      it "returns AttributeBinding" do
        assert_kind_of XML::AttributeBinding, @Band.binding_for_definition(Def.new(:band, :from => "@band"))
      end
      
      it "returns ObjectBinding" do
        assert_kind_of XML::ObjectBinding, @Band.binding_for_definition(Def.new(:band, :as => Hash))
      end
      
      it "returns TextBinding" do
        assert_kind_of XML::TextBinding, @Band.binding_for_definition(Def.new(:band, :from => :content))
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
        band = Band.new("Bad Religion")
        album = Album.new(band)
        
        assert_xml_equal %{<album>
         <band>
           <name>Bad Religion</name>
         </band>
       </album>}, album.to_xml
      end
      
      it "doesn't escape and wrap string from Band#to_node" do
        band = Band.new("Bad Religion")
        band.instance_eval do
          def to_node
            "<band>Baaaad Religion</band>"
          end
        end
        
        assert_xml_equal %{<album><band>Baaaad Religion</band></album>}, Album.new(band).to_xml
      end
    end
  end
end


class CollectionTest < MiniTest::Spec
  describe ":as => Band, :from => :band, :collection => true" do
    class Compilation
      include Representable::XML
      representable_collection :bands, :as => Band, :from => :band
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
      </compilation>}, cd.to_xml
    end
  end
    
    
  describe ":from" do
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
