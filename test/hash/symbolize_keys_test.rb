require 'test_helper'
require 'representable/hash/symbolize_keys'

class SymbolizeKeysTest < MiniTest::Spec

  describe 'to_hash' do
    it 'should symbolize keys' do
      module SongRepresenter
        include Representable::Hash
        include Representable::Hash::SymbolizeKeys
        property :title
      end

      class Song < Struct.new(:title) ; end
      Song.new('a title').extend(SongRepresenter).to_hash.must_equal(title: 'a title')
    end
  end
end
