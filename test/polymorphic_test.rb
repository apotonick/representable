require 'test_helper'

module PopSongRepresenter
  include Representable::JSON
    property :name, :from => "known_as"
end

module SongRepresenter
  include Representable::JSON
    property :name
end

module AlbumRepresenter
  include Representable::JSON
  collection :songs, :extend => PolymorphicExtender
end
 
class PolymorphicTest < MiniTest::Spec
  class PopSong < Song
  end
 
  class Album
    attr_accessor :songs
  end
  
  describe "PolymorphicExtender" do
    it "extends each model with the correct representer in #to_json" do
      album = Album.new
      album.songs = [PopSong.new("Let Me Down"), Song.new("The 4 Horsemen")]
      assert_equal "{\"songs\":[{\"known_as\":\"Let Me Down\"},{\"name\":\"The 4 Horsemen\"}]}", album.extend(AlbumRepresenter).to_json
    end
  end
end
