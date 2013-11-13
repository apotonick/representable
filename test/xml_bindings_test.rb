require 'test_helper'
require 'representable/json'  # FIXME.
require 'representable/xml/collection'
require 'representable/xml/hash'

require 'representable/xml'

class XMLBindingTest < MiniTest::Spec
  module SongRepresenter
    include Representable::XML
    property :name
    self.representation_wrap = :song
  end
  
  class SongWithRepresenter < ::Song
    include Representable
    include SongRepresenter
    self.representation_wrap = :song
  end
  
  before do
    @doc  = Nokogiri::XML::Document.new
    @song = SongWithRepresenter.new("Thinning the Herd")
  end
  
  describe "PropertyBinding" do
    describe "with plain text" do
      before do
        @property = Representable::XML::PropertyBinding.new(Representable::Definition.new(:song), nil)
      end
      
      it "extracts with #read" do
        assert_equal "Thinning the Herd", @property.read(Nokogiri::XML("<song>Thinning the Herd</song>"))
      end
      
      it "inserts with #write" do
        @property.write(@doc, "Thinning the Herd")
        assert_xml_equal "<song>Thinning the Herd</song>", @doc.to_s
      end
    end
    
    describe "with an object" do
      before do
        @property = Representable::XML::PropertyBinding.new(Representable::Definition.new(:song, :class => SongWithRepresenter), nil)
      end
      
      it "extracts with #read" do
        assert_equal @song, @property.read(Nokogiri::XML("<song><name>Thinning the Herd</name></song>"))
      end
      
      it "inserts with #write" do
        @property.write(@doc, @song)
        assert_xml_equal("<song><name>Thinning the Herd</name></song>", @doc.to_s)
      end
    end
    
    describe "with an object and :extend" do
      before do
        @property = Representable::XML::PropertyBinding.new(Representable::Definition.new(:song, :class => Song, :extend => SongRepresenter), nil)
      end
      
      it "extracts with #read" do
        assert_equal @song, @property.read(Nokogiri::XML("<song><name>Thinning the Herd</name></song>"))
      end
      
      it "inserts with #write" do
        @property.write(@doc, @song)
        assert_xml_equal("<song><name>Thinning the Herd</name></song>", @doc.to_s)
      end
    end
  end
  
    
  describe "CollectionBinding" do
    describe "with plain text items" do
      before do
        @property = Representable::XML::CollectionBinding.new(Representable::Definition.new(:song, :collection => true), nil)
      end
      
      it "extracts with #read" do
        assert_equal ["The Gargoyle", "Bronx"], @property.read(Nokogiri::XML("<doc><song>The Gargoyle</song><song>Bronx</song></doc>").root)
      end
      
      it "inserts with #write" do
        parent = Nokogiri::XML::Node.new("parent", @doc)
        @property.write(parent, ["The Gargoyle", "Bronx"])
        assert_xml_equal("<songs><song>The Gargoyle</song><song>Bronx</song></songs>", parent.to_s)
      end
    end
    
    describe "with objects" do
      before do
        @property = Representable::XML::PropertyBinding.new(Representable::Definition.new(:song, :collection => true, :class => SongWithRepresenter), nil)
      end
      
      it "extracts with #read" do
        assert_equal @song, @property.read(Nokogiri::XML("<song><name>Thinning the Herd</name></song>"))
      end
      
      it "inserts with #write" do
        @property.write(@doc, @song)
        assert_xml_equal("<song><name>Thinning the Herd</name></song>", @doc.to_s)
        assert_kind_of Nokogiri::XML::Node, @doc.children.first
        assert_equal "song", @doc.children.first.name
        assert_equal "name", @doc.children.first.children.first.name
      end
    end
  end
  
  
  describe "HashBinding" do
    describe "with plain text items" do
      before do
        @property = Representable::XML::HashBinding.new(Representable::Definition.new(:songs, :hash => true), nil)
      end
      
      it "extracts with #read" do
        assert_equal({"first" => "The Gargoyle", "second" => "Bronx"} , @property.read(Nokogiri::XML("<songs><first>The Gargoyle</first><second>Bronx</second></songs>")))
      end
      
      it "inserts with #write" do
        parent = Nokogiri::XML::Node.new("parent", @doc)
        @property.write(parent, {"first" => "The Gargoyle", "second" => "Bronx"})
        assert_xml_equal("<songs><first>The Gargoyle</first><second>Bronx</second></songs>", parent.to_s)
      end
    end
    
    describe "with objects" do
      before do
        @property = Representable::XML::HashBinding.new(Representable::Definition.new(:songs, :hash => true, :class => Song, :extend => SongRepresenter), nil)
      end
    end
  end
  
  
  describe "AttributeBinding" do
    describe "with plain text items" do
      before do
        @property = Representable::XML::AttributeBinding.new(Representable::Definition.new(:name, :attribute => true), nil)
      end
      
      it "extracts with #read" do
        assert_equal "The Gargoyle", @property.read(Nokogiri::XML("<song name=\"The Gargoyle\" />").root)
      end
      
      it "inserts with #write" do
        parent = Nokogiri::XML::Node.new("song", @doc)
        @property.write(parent, "The Gargoyle")
        assert_xml_equal("<song name=\"The Gargoyle\" />", parent.to_s)
      end
    end
  end

  describe "ContentBinding" do
    before do
      @property = Representable::XML::ContentBinding.new(Representable::Definition.new(:name, :content => true), nil)
    end
    
    it "extracts with #read" do
      assert_equal "The Gargoyle", @property.read(Nokogiri::XML("<song>The Gargoyle</song>").root)
    end
    
    it "inserts with #write" do
      parent = Nokogiri::XML::Node.new("song", @doc)
      @property.write(parent, "The Gargoyle")
      assert_xml_equal("<song>The Gargoyle</song>", parent.to_s)
    end
  end
end
