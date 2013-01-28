require 'test_helper'
require 'representable/coercion'

class VirtusCoercionTest < MiniTest::Spec
  class Song  # note that we don't define accessors for the properties here.
  end

  describe "Coercion with Virtus" do
    describe "on object level" do
      module SongRepresenter
        include Representable::JSON
        include Representable::Coercion
        property :composed_at,  :type => DateTime
        property :track,        :type => Integer
      end

      it "coerces properties in #from_json" do
        song = Song.new.extend(SongRepresenter).from_json("{\"composed_at\":\"November 18th, 1983\",\"track\":\"18\"}")
        assert_kind_of DateTime, song.composed_at
        assert_equal 18, song.track
        assert_equal DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000"), song.composed_at
      end
    end


    describe "on class level" do
      class ImmigrantSong
        include Representable::JSON
        include Representable::Coercion

        property :composed_at,  :type => DateTime, :default => "May 12th, 2012"
        property :track,        :type => Integer

        def track=(track_number)
          # Not very elegant, but this is just a quick demo
          track_number = attribute_set[:track].coerce(track_number)
          track_number = 1 if track_number < 0
          super(track_number)
        end
      end

      it "coerces into the provided type" do
        song = ImmigrantSong.new.from_json("{\"composed_at\":\"November 18th, 1983\",\"track\":\"18\"}")
        assert_equal DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000"), song.composed_at
        assert_equal 18, song.track
      end

      it "respects the :default options" do
        song = ImmigrantSong.new.from_json("{}")
        assert_kind_of DateTime, song.composed_at
        assert_equal DateTime.parse("Mon, 12 May 2012 00:00:00 +0000"), song.composed_at
      end

      it "can override and re-use Virtus accessors" do
        song = ImmigrantSong.new.from_json('{"track": -5}')
        assert_equal 1, song.track
      end
    end

  end
end
