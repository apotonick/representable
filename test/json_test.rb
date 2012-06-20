require 'test_helper'

module JsonTest
  class APITest < MiniTest::Spec
    Json = Representable::JSON
    Def = Representable::Definition

    describe "JSON module" do
      before do
        @Band = Class.new do
          include Representable::JSON
          property :name
          property :label
          attr_accessor :name, :label

          def initialize(name=nil)
            self.name = name if name
          end
        end

        @band = @Band.new
      end


      describe ".from_json" do
        it "is delegated to #from_json" do
          block = lambda {|*args|}
          @Band.any_instance.expects(:from_json).with("{document}", "options") # FIXME: how to NOT expect block?
          @Band.from_json("{document}", "options", &block)
        end

        it "yields new object and options to block" do
          @Band.class_eval { attr_accessor :new_name }
          @band = @Band.from_json("{}", :new_name => "Diesel Boy") do |band, options|
            band.new_name= options[:new_name]
          end
          assert_equal "Diesel Boy", @band.new_name
        end
      end


      describe ".from_hash" do
        it "is delegated to #from_hash not passing the block" do
          block = lambda {|*args|}
          @Band.any_instance.expects(:from_hash).with("{document}", "options") # FIXME: how to NOT expect block?
          @Band.from_hash("{document}", "options", &block)
        end

        it "yields new object and options to block" do
          @Band.class_eval { attr_accessor :new_name }
          @band = @Band.from_hash({}, :new_name => "Diesel Boy") do |band, options|
            band.new_name= options[:new_name]
          end

          assert_equal "Diesel Boy", @band.new_name
        end
      end


      describe "#from_json" do
        before do
          @band = @Band.new
          @json  = {:name => "Nofx", :label => "NOFX"}.to_json
        end

        it "parses JSON and assigns properties" do
          @band.from_json(@json)
          assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
        end
      end


      describe "#from_hash" do
        before do
          @band = @Band.new
          @hash  = {"name" => "Nofx", "label" => "NOFX"}
        end

        it "receives hash and assigns properties" do
          @band.from_hash(@hash)
          assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
        end

        it "respects :wrap option" do
          @band.from_hash({"band" => {"name" => "This Is A Standoff"}}, :wrap => :band)
          assert_equal "This Is A Standoff", @band.name
        end

        it "respects :wrap option over representation_wrap" do
          @Band.class_eval do
            self.representation_wrap = :group
          end
          @band.from_hash({"band" => {"name" => "This Is A Standoff"}}, :wrap => :band)
          assert_equal "This Is A Standoff", @band.name
        end
      end


      describe "#to_json" do
        it "delegates to #to_hash and returns string" do
          assert_json "{\"name\":\"Rise Against\"}", @Band.new("Rise Against").to_json
        end
      end


      describe "#to_hash" do
        it "returns unwrapped hash" do
          hash = @Band.new("Rise Against").to_hash
          assert_equal({"name"=>"Rise Against"}, hash)
        end

        it "respects #representation_wrap=" do
          @Band.representation_wrap = :group
          assert_equal({:group=>{"name"=>"Rise Against"}}, @Band.new("Rise Against").to_hash)
        end

        it "respects :wrap option" do
          assert_equal({:band=>{"name"=>"NOFX"}}, @Band.new("NOFX").to_hash(:wrap => :band))
        end

        it "respects :wrap option over representation_wrap" do
          @Band.class_eval do
            self.representation_wrap = :group
          end
          assert_equal({:band=>{"name"=>"Rise Against"}}, @Band.new("Rise Against").to_hash(:wrap => :band))
        end
      end

      describe "#binding_for_definition" do
        it "returns ObjectBinding" do
          assert_kind_of Json::ObjectBinding, Json.binding_for_definition(Def.new(:band, :class => Hash))
        end

        it "returns TextBinding" do
          assert_kind_of Json::PropertyBinding, Json.binding_for_definition(Def.new(:band))
        end

        it "returns HashBinding" do
          assert_kind_of Json::HashBinding, Json.binding_for_definition(Def.new(:band, :hash => true))
        end

        it "returns CollectionBinding" do
          assert_kind_of Json::CollectionBinding, Json.binding_for_definition(Def.new(:band, :collection => true))
        end
      end

      describe "#representable_bindings" do
        it "returns bindings for each property" do
          assert_equal 2, @band.send(:representable_bindings_for, Json).size
          assert_equal "name", @band.send(:representable_bindings_for, Json).first.definition.name
        end
      end
    end


    describe "DCI" do
      module SongRepresenter
        include Representable::JSON
        property :name
      end

      module AlbumRepresenter
        include Representable::JSON
        property :best_song, :class => Song, :extend => SongRepresenter
        collection :songs, :class => Song, :extend => [SongRepresenter]
      end


      it "allows adding the representer by using #extend" do
        module BandRepresenter
          include Representable::JSON
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
        assert_json "{\"name\":\"CIV\"}", civ.to_json
      end

      it "extends contained models when serializing" do
        @album = Album.new(Song.new("I Hate My Brain"), Song.new("Mr. Charisma"))
        @album.extend(AlbumRepresenter)

        assert_json "{\"best_song\":{\"name\":\"Mr. Charisma\"},\"songs\":[{\"name\":\"I Hate My Brain\"},{\"name\":\"Mr. Charisma\"}]}", @album.to_json
      end

      it "extends contained models when deserializing" do
        #@album = Album.new(Song.new("I Hate My Brain"), Song.new("Mr. Charisma"))
        @album = Album.new
        @album.extend(AlbumRepresenter)

        @album.from_json("{\"best_song\":{\"name\":\"Mr. Charisma\"},\"songs\":[{\"name\":\"I Hate My Brain\"},{\"name\":\"Mr. Charisma\"}]}")
        assert_equal "Mr. Charisma", @album.best_song.name
      end
    end
  end


  class PropertyTest < MiniTest::Spec
    describe "property :name" do
      class Band
        include Representable::JSON
        property :name
        attr_accessor :name
      end

      it "#from_json creates correct accessors" do
        band = Band.from_json({:name => "Bombshell Rocks"}.to_json)
        assert_equal "Bombshell Rocks", band.name
      end

      it "#to_json serializes correctly" do
        band = Band.new
        band.name = "Cigar"

        assert_json '{"name":"Cigar"}', band.to_json
      end
    end

    describe ":class => Item" do
      class Label
        include Representable::JSON
        property :name
        attr_accessor :name
      end

      class Album
        include Representable::JSON
        property :label, :class => Label
        attr_accessor :label
      end

      it "#from_json creates one Item instance" do
        album = Album.from_json('{"label":{"name":"Fat Wreck"}}')
        assert_equal "Fat Wreck", album.label.name
      end

      it "#to_json serializes" do
        label = Label.new; label.name = "Fat Wreck"
        album = Album.new; album.label = label

        assert_json '{"label":{"name":"Fat Wreck"}}', album.to_json
      end

      describe ":different_name, :class => Label" do
        before do
          @Album = Class.new do
            include Representable::JSON
            property :seller, :class => Label
            attr_accessor :seller
          end
        end

        it "#to_xml respects the different name" do
          label = Label.new; label.name = "Fat Wreck"
          album = @Album.new; album.seller = label

          assert_json "{\"seller\":{\"name\":\"Fat Wreck\"}}", album.to_json(:wrap => false)
        end
      end
    end

    describe ":from => :songName" do
      class Song
        include Representable::JSON
        property :name, :from => :songName
        attr_accessor :name
      end

      it "respects :from in #from_json" do
        song = Song.from_json({:songName => "Run To The Hills"}.to_json)
        assert_equal "Run To The Hills", song.name
      end

      it "respects :from in #to_json" do
        song = Song.new; song.name = "Run To The Hills"
        assert_json '{"songName":"Run To The Hills"}', song.to_json
      end
    end

    describe ":default => :value" do
      before do
        @Album = Class.new do
        include Representable::JSON
        property :name, :default => "30 Years Live"
        attr_accessor :name
      end
    end

    describe "#from_json" do
      it "uses default when property nil in doc" do
        album = @Album.from_json({}.to_json)
        assert_equal "30 Years Live", album.name
      end

      it "uses value from doc when present" do
        album = @Album.from_json({:name => "Live At The Wireless"}.to_json)
        assert_equal "Live At The Wireless", album.name
      end

      it "uses value from doc when empty string" do
        album = @Album.from_json({:name => ""}.to_json)
        assert_equal "", album.name
      end
    end

    describe "#to_json" do
      it "uses default when not available in object" do
        assert_json "{\"name\":\"30 Years Live\"}", @Album.new.to_json
      end

      it "uses value from represented object when present" do
        album = @Album.new
        album.name = "Live At The Wireless"
        assert_json "{\"name\":\"Live At The Wireless\"}", album.to_json
      end

      it "uses value from represented object when emtpy string" do
        album = @Album.new
        album.name = ""
        assert_json "{\"name\":\"\"}", album.to_json
      end
    end
  end
end


  class CollectionTest < MiniTest::Spec
    describe "collection :name" do
      class CD
        include Representable::JSON
        collection :songs
        attr_accessor :songs
      end

      it "#from_json creates correct accessors" do
        cd = CD.from_json({:songs => ["Out in the cold", "Microphone"]}.to_json)
        assert_equal ["Out in the cold", "Microphone"], cd.songs
      end

      it "#to_json serializes correctly" do
        cd = CD.new
        cd.songs = ["Out in the cold", "Microphone"]

        assert_json '{"songs":["Out in the cold","Microphone"]}', cd.to_json
      end
    end

    describe "collection :name, :class => Band" do
      class Band
        include Representable::JSON
        property :name
        attr_accessor :name

        def initialize(name="")
          self.name = name
        end
      end

      class Compilation
        include Representable::JSON
        collection :bands, :class => Band
        attr_accessor :bands
      end

      describe "#from_json" do
        it "pushes collection items to array" do
          cd = Compilation.from_json({:bands => [
            {:name => "Cobra Skulls"},
            {:name => "Diesel Boy"}]}.to_json)
          assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
        end

        it "creates emtpy array from default if configured" do
          cd = Compilation.from_json({}.to_json)
          assert_equal [], cd.bands
        end
      end

      it "responds to #to_json" do
        cd = Compilation.new
        cd.bands = [Band.new("Diesel Boy"), Band.new("Bad Religion")]

        assert_json '{"bands":[{"name":"Diesel Boy"},{"name":"Bad Religion"}]}', cd.to_json
      end
    end


    describe ":from => :songList" do
      class Songs
        include Representable::JSON
        collection :tracks, :from => :songList
        attr_accessor :tracks
      end

      it "respects :from in #from_json" do
        songs = Songs.from_json({:songList => ["Out in the cold", "Microphone"]}.to_json)
        assert_equal ["Out in the cold", "Microphone"], songs.tracks
      end

      it "respects option in #to_json" do
        songs = Songs.new
        songs.tracks = ["Out in the cold", "Microphone"]

        assert_json '{"songList":["Out in the cold","Microphone"]}', songs.to_json
      end
    end
  end

  class HashTest < MiniTest::Spec
    describe "hash :songs" do
      before do
        representer = Module.new do
          include Representable::JSON
          hash :songs
        end

        class SongList
          attr_accessor :songs
        end

        @list = SongList.new.extend(representer)
      end

      it "renders with #to_json" do
        @list.songs = {:one => "65", :two => "Emo Boy"}
        assert_json "{\"songs\":{\"one\":\"65\",\"two\":\"Emo Boy\"}}", @list.to_json
      end

      it "parses with #from_json" do
        assert_equal({"one" => "65", "two" => ["Emo Boy"]}, @list.from_json("{\"songs\":{\"one\":\"65\",\"two\":[\"Emo Boy\"]}}").songs)
      end
    end

  end


  require 'representable/json/collection'
  class CollectionRepresenterTest < MiniTest::Spec
    module SongRepresenter
      include Representable::JSON
      property :name
    end

    describe "JSON::Collection" do
      describe "with contained objects" do
        before do
          @songs_representer = Module.new do
            include Representable::JSON::Collection
            items :class => Song, :extend => SongRepresenter
          end
        end

        it "renders objects with #to_json" do
          assert_json "[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]", [Song.new("Days Go By"), Song.new("Can't Take Them All")].extend(@songs_representer).to_json
        end

        it "returns objects array from #from_json" do
          assert_equal [Song.new("Days Go By"), Song.new("Can't Take Them All")], [].extend(@songs_representer).from_json("[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]")
        end
      end

      describe "with contained text" do
        before do
          @songs_representer = Module.new do
            include Representable::JSON::Collection
          end
        end

        it "renders contained items #to_json" do
          assert_json "[\"Days Go By\",\"Can't Take Them All\"]", ["Days Go By", "Can't Take Them All"].extend(@songs_representer).to_json
        end

        it "returns objects array from #from_json" do
          assert_equal ["Days Go By", "Can't Take Them All"], [].extend(@songs_representer).from_json("[\"Days Go By\",\"Can't Take Them All\"]")
        end
      end
    end
  end


  require 'representable/json/hash'
  class HashRepresenterTest < MiniTest::Spec
    module SongRepresenter
      include Representable::JSON
      property :name
    end

    describe "JSON::Hash" do  # TODO: move to HashTest.
      describe "with contained objects" do
        before do
          @songs_representer = Module.new do
            include Representable::JSON::Hash
            values :class => Song, :extend => SongRepresenter
          end
        end

        describe "#to_json" do
          it "renders objects" do
            assert_json "{\"one\":{\"name\":\"Days Go By\"},\"two\":{\"name\":\"Can't Take Them All\"}}", {:one => Song.new("Days Go By"), :two => Song.new("Can't Take Them All")}.extend(@songs_representer).to_json
          end

          it "respects :exclude" do
            assert_json "{\"two\":{\"name\":\"Can't Take Them All\"}}", {:one => Song.new("Days Go By"), :two => Song.new("Can't Take Them All")}.extend(@songs_representer).to_json(:exclude => [:one])
          end

          it "respects :include" do
            assert_json "{\"two\":{\"name\":\"Can't Take Them All\"}}", {:one => Song.new("Days Go By"), :two => Song.new("Can't Take Them All")}.extend(@songs_representer).to_json(:include => [:two])
          end
        end

        describe "#from_json" do
          it "returns objects array" do
            assert_equal({"one" => Song.new("Days Go By"), "two" => Song.new("Can't Take Them All")}, {}.extend(@songs_representer).from_json("{\"one\":{\"name\":\"Days Go By\"},\"two\":{\"name\":\"Can't Take Them All\"}}"))
          end

          it "respects :exclude" do
            assert_equal({"two" => Song.new("Can't Take Them All")}, {}.extend(@songs_representer).from_json("{\"one\":{\"name\":\"Days Go By\"},\"two\":{\"name\":\"Can't Take Them All\"}}", :exclude => [:one]))
          end

          it "respects :include" do
            assert_equal({"one" => Song.new("Days Go By")}, {}.extend(@songs_representer).from_json("{\"one\":{\"name\":\"Days Go By\"},\"two\":{\"name\":\"Can't Take Them All\"}}", :include => [:one]))
          end
        end
      end

      describe "with contained text" do
        before do
          @songs_representer = Module.new do
            include Representable::JSON::Collection
          end
        end

        it "renders contained items #to_json" do
          assert_json "[\"Days Go By\",\"Can't Take Them All\"]", ["Days Go By", "Can't Take Them All"].extend(@songs_representer).to_json
        end

        it "returns objects array from #from_json" do
          assert_equal ["Days Go By", "Can't Take Them All"], [].extend(@songs_representer).from_json("[\"Days Go By\",\"Can't Take Them All\"]")
        end
      end
    end
  end
end
