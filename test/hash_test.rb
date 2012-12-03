require 'test_helper'
require 'representable/hash'

class YamlTest < MiniTest::Spec
  def self.hash_representer(&block)
    Module.new do
      include Representable::Hash
      instance_exec &block
    end
  end

  def hash_representer(&block)
    self.class.hash_representer(&block)
  end


  describe "property" do
    let (:hash) { hash_representer do property :best_song end }

    let (:album) { Album.new.tap do |album|
      album.best_song = "Liar"
    end }

    describe "#to_hash" do
      it "renders plain property" do
        album.extend(hash).to_hash.must_equal("best_song" => "Liar")
      end
    end


    describe "#from_hash" do
      it "parses plain property" do
        album.extend(hash).from_hash("best_song" => "This Song Is Recycled").best_song.must_equal "This Song Is Recycled"
      end
    end


    describe "with :class and :extend" do
      hash_song = hash_representer do property :name end
      let (:hash_album) { Module.new do
        include Representable::Hash
        property :best_song, :extend => hash_song, :class => Song
      end }

      let (:album) { Album.new.tap do |album|
        album.best_song = Song.new("Liar")
      end }


      describe "#to_hash" do
        it "renders embedded typed property" do
          album.extend(hash_album).to_hash.must_equal("best_song" => {"name" => "Liar"})
        end
      end

      describe "#from_hash" do
        it "parses embedded typed property" do
          album.extend(hash_album).from_hash("best_song" => {"name" => "Go With Me"}).must_equal Album.new(nil,Song.new("Go With Me"))
        end
      end
    end
  end


  describe "collection" do
    let (:hash) { hash_representer do collection :songs end }

    let (:album) { Album.new.tap do |album|
      album.songs = ["Jackhammer", "Terrible Man"]
    end }


    describe "#to_hash" do
      it "renders a block style list per default" do
        album.extend(hash).to_hash.must_equal("songs" => ["Jackhammer", "Terrible Man"])
      end
    end


    describe "#from_hash" do
      it "parses a block style list" do
        album.extend(hash).from_hash("songs" => ["Off Key Melody", "Sinking"]).must_equal Album.new(["Off Key Melody", "Sinking"])

      end
    end


    describe "with :class and :extend" do
      hash_song = hash_representer do 
        property :name
        property :track
      end
      let (:hash_album) { Module.new do
        include Representable::Hash
        collection :songs, :extend => hash_song, :class => Song
      end }

      let (:album) { Album.new.tap do |album|
        album.songs = [Song.new("Liar", 1), Song.new("What I Know", 2)]
      end }


      describe "#to_hash" do
        it "renders collection of typed property" do
          album.extend(hash_album).to_hash.must_equal("songs" => [{"name" => "Liar", "track" => 1}, {"name" => "What I Know", "track" => 2}])
        end
      end

      describe "#from_hash" do
        it "parses collection of typed property" do
          album.extend(hash_album).from_hash("songs" => [{"name" => "One Shot Deal", "track" => 4},
            {"name" => "Three Way Dance", "track" => 5}]).must_equal Album.new([Song.new("One Shot Deal", 4), Song.new("Three Way Dance", 5)])
        end
      end
    end
  end


  class DefinitionTest < MiniTest::Spec
    it "what" do
      class Representable::Hash::Binding < SimpleDelegator
        
      end

      definition  = Representable::Definition.new(:name)
      wrapped     = Representable::Hash::Binding.new(definition)

      wrapped.name.must_equal "name"
      wrapped.hash?.must_equal false
      wrapped.array?.must_equal false
      wrapped.options.must_equal({})

      #wrapped.
    end
  end
end