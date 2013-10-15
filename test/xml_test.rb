require 'test_helper'
require 'representable/xml'

class Band
  include Representable::XML
  property :name
  attr_accessor :name

  def initialize(name=nil)
    name and self.name = name
  end
end

class Album
  attr_accessor :songs
end


class XmlTest < MiniTest::Spec
  XML = Representable::XML
  Def = Representable::Definition

  describe "Xml module" do
    before do
      @Band = Class.new do
        include Representable::XML
        self.representation_wrap = :band
        property :name
        property :label
        attr_accessor :name, :label
      end

      @band = @Band.new
    end


    describe ".from_xml" do
      it "is delegated to #from_xml" do
        block = lambda {|*args|}
        @Band.any_instance.expects(:from_xml).with("<document>", "options") # FIXME: how to NOT expect block?
        @Band.from_xml("<document>", "options", &block)
      end

      it "yields new object and options to block" do
        @Band.class_eval { attr_accessor :new_name }
        @band = @Band.from_xml("<band/>", :new_name => "Diesel Boy") do |band, options|
          band.new_name= options[:new_name]
        end
        assert_equal "Diesel Boy", @band.new_name
      end
    end


    describe ".from_node" do
      it "is delegated to #from_node" do
        block = lambda {|*args|}
        @Band.any_instance.expects(:from_node).with("<document>", "options") # FIXME: how to expect block?
        @Band.from_node("<document>", "options", &block)
      end

      it "yields new object and options to block" do
        @Band.class_eval { attr_accessor :new_name }
        @band = @Band.from_node(Nokogiri::XML("<band/>"), :new_name => "Diesel Boy") do |band, options|
          band.new_name= options[:new_name]
        end
        assert_equal "Diesel Boy", @band.new_name
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
    end

    describe "#from_xml with remove_namespaces! and xmlns present" do
      before do
        @Band.remove_namespaces!
        @band = @Band.new
        @xml = %{<band xmlns="exists"><name>Nofx</name><label>NOFX</label></band>}
      end

      it "parses with xmlns present" do
        @band.from_xml(@xml)
        assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
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
    end


    describe "#to_xml" do
      it "delegates to #to_node and returns string" do
        assert_xml_equal "<band><name>Rise Against</name></band>", Band.new("Rise Against").to_xml
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
        klass = Class.new(Band) do
          include Representable
          property :name
        end

        klass.representation_wrap = :group
        assert_xml_equal "<group><name>Rise Against</name></group>", klass.new("Rise Against").to_node.to_s
      end
    end


    describe "XML::Binding#build_for" do
      it "returns AttributeBinding" do
        assert_kind_of XML::AttributeBinding, XML::PropertyBinding.build_for(Def.new(:band, :from => "band", :attribute => true), nil)
      end

      it "returns PropertyBinding" do
        assert_kind_of XML::PropertyBinding, XML::PropertyBinding.build_for(Def.new(:band, :class => Hash), nil)
        assert_kind_of XML::PropertyBinding, XML::PropertyBinding.build_for(Def.new(:band, :from => :content), nil)
      end

      it "returns CollectionBinding" do
        assert_kind_of XML::CollectionBinding, XML::PropertyBinding.build_for(Def.new(:band, :collection => :true), nil)
      end

      it "returns HashBinding" do
        assert_kind_of XML::HashBinding, XML::PropertyBinding.build_for(Def.new(:band, :hash => :true), nil)
      end
    end


    describe "DCI" do
      module SongRepresenter
        include Representable::XML
        property :name
        representation_wrap = :song
      end

      module AlbumRepresenter
        include Representable::XML
        property :best_song, :class => Song, :extend => SongRepresenter
        collection :songs, :class => Song, :from => :song, :extend => SongRepresenter
        representation_wrap = :album
      end


      it "allows adding the representer by using #extend" do
        module BandRepresenter
          include Representable::XML
          property :name
        end

        civ = Object.new
        civ.instance_eval do
          def name; "CIV"; end
          def name=(v)
            @name = v
          end
        end

        civ.extend(BandRepresenter)
        assert_xml_equal "<object><name>CIV</name></object>", civ.to_xml
      end

      it "extends contained models when serializing" do
        @album = Album.new([Song.new("I Hate My Brain"), mr=Song.new("Mr. Charisma")], mr)
        @album.extend(AlbumRepresenter)

        assert_xml_equal "<album>
  <song><name>Mr. Charisma</name></song>
  <song><name>I Hate My Brain</name></song>
  <song><name>Mr. Charisma</name></song>
</album>", @album.to_xml
      end

      it "extends contained models when deserializing" do
        @album = Album.new
        @album.extend(AlbumRepresenter)

        @album.from_xml("<album><best_song><name>Mr. Charisma</name></best_song><song><name>I Hate My Brain</name></song><song><name>Mr. Charisma</name></song></album>")
        assert_equal "Mr. Charisma", @album.best_song.name
      end
    end
  end
end


class AttributesTest < MiniTest::Spec
  describe ":from => rel, :attribute => true" do
    class Link
      include Representable::XML
      property :href,   :from => "href",  :attribute => true
      property :title,  :from => "title", :attribute => true
      attr_accessor :href, :title
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
  module AlbumRepresenter
    include Representable::XML
    property :band, :class => Band
  end


  class Album
    attr_accessor :band
    def initialize(band=nil)
      @band = band
    end
  end

  # TODO:property :group, :class => Band
  # :class
  # where to mixin DCI?
  describe ":class => Item" do
    it "#from_xml creates one Item instance" do
      album = Album.new.extend(AlbumRepresenter).from_xml(%{
        <album>
          <band><name>Bad Religion</name></band>
        </album>
      })
      assert_equal "Bad Religion", album.band.name
    end

    describe "#to_xml" do
      it "doesn't escape xml from Band#to_xml" do
        band = Band.new("Bad Religion")
        album = Album.new(band).extend(AlbumRepresenter)

        assert_xml_equal %{<album>
         <band>
           <name>Bad Religion</name>
         </band>
       </album>}, album.to_xml
      end

      it "doesn't escape and wrap string from Band#to_node" do
        band = Band.new("Bad Religion")
        band.instance_eval do
          def to_node(*)
            "<band>Baaaad Religion</band>"
          end
        end

        assert_xml_equal %{<album><band>Baaaad Religion</band></album>}, Album.new(band).extend(AlbumRepresenter).to_xml
      end
    end
  end
end


class CollectionTest < MiniTest::Spec
  describe ":class => Band, :from => :band, :collection => true" do
    class Compilation
      include Representable::XML
      collection :bands, :class => Band, :from => :band
      attr_accessor :bands
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

      it "collections can be empty when default set" do
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
    let(:xml) {
      Module.new do
        include Representable::XML
        collection :songs, :from => :song
      end }

    it "collects untyped items" do
      album = Album.new.extend(xml).from_xml(%{
        <album>
          <song>Two Kevins</song>
          <song>Wright and Rong</song>
          <song>Laundry Basket</song>
        </album>
      })
      assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
    end
  end


  describe ":wrap" do
    let (:album) { Album.new.extend(xml) }
    let (:xml) {
      Module.new do
        include Representable::XML
        collection :songs, :from => :song, :wrap => :songs
      end }

    describe "#from_xml" do
      it "finds items in wrapped collection" do
        album.from_xml(%{
          <album>
            <songs>
              <song>Two Kevins</song>
              <song>Wright and Rong</song>
              <song>Laundry Basket</song>
            </songs>
          </album>
        })
        assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
      end
    end

    describe "#to_xml" do
      it "wraps items" do
        album.songs = ["Laundry Basket", "Two Kevins", "Wright and Rong"]
        assert_xml_equal %{
          <album>
            <songs>
              <song>Laundry Basket</song>
              <song>Two Kevins</song>
              <song>Wright and Rong</song>
            </songs>
          </album>
        }, album.to_xml
      end
    end
  end

  require 'representable/xml/collection'
  require 'representable/xml/hash'
  class LonelyRepresenterTest < MiniTest::Spec
    # TODO: where is the XML::Hash test?
    module SongRepresenter
      include Representable::XML
      property :name
    end

    let (:decorator) { rpr = representer; Class.new(Representable::Decorator) { include rpr; self.representation_wrap= :songs } } # FIXME: why isn't representation wrap inherited properly?

    describe "XML::Collection" do
      describe "with contained objects" do
        representer!(Representable::XML::Collection)  do
          items :class => Song, :extend => SongRepresenter
          self.representation_wrap= :songs
        end

        let (:songs) { [Song.new("Days Go By"), Song.new("Can't Take Them All")] }
        let (:xml)   { "<songs><song><name>Days Go By</name></song><song><name>Can't Take Them All</name></song></songs>" }

        it "renders array" do
          songs.extend(representer).to_xml.must_equal_xml xml
        end

        it "renders array with decorator" do
          decorator.new(songs).to_xml.must_equal_xml xml
        end

        it "parses array" do
          [].extend(representer).from_xml(xml).must_equal songs
        end

        it "parses array with decorator" do
          decorator.new([]).from_xml(xml).must_equal songs
        end
      end
    end

    describe "XML::AttributeHash" do  # TODO: move to HashTest.
      representer!(Representable::XML::AttributeHash) do
        self.representation_wrap= :songs
      end

      let (:songs) { {"one" => "Graveyards", "two" => "Can't Take Them All"} }
      let (:xml)   { "<favs one=\"Graveyards\" two=\"Can't Take Them All\" />" }

      describe "#to_xml" do
        it "renders hash" do
          songs.extend(representer).to_xml.must_equal_xml xml
        end

        it "respects :exclude" do
          assert_xml_equal "<favs two=\"Can't Take Them All\" />", songs.extend(representer).to_xml(:exclude => [:one])
        end

        it "respects :include" do
          assert_xml_equal "<favs two=\"Can't Take Them All\" />", songs.extend(representer).to_xml(:include => [:two])
        end

        it "renders hash with decorator" do
          decorator.new(songs).to_xml.must_equal_xml xml
        end
      end

      describe "#from_json" do
        it "returns hash" do
          {}.extend(representer).from_xml(xml).must_equal songs
        end

        it "respects :exclude" do
          assert_equal({"two" => "Can't Take Them All"}, {}.extend(representer).from_xml(xml, :exclude => [:one]))
        end

        it "respects :include" do
          assert_equal({"one" => "Graveyards"}, {}.extend(representer).from_xml(xml, :include => [:one]))
        end

        it "parses hash with decorator" do
          decorator.new({}).from_xml(xml).must_equal songs
        end
      end
    end
  end
end
