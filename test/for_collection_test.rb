require 'test_helper'

class ForCollectionTest < MiniTest::Spec
  module SongRepresenter
    include Representable::JSON

    property :name
  end

  let(:songs) { [Song.new("Days Go By"), Song.new("Can't Take Them All")] }
  let(:json)  { "[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]" }


  # Module.for_collection
  # Decorator.for_collection
  for_formats(
    :hash => [Representable::Hash, out=[{"name" => "Days Go By"}, {"name"=>"Can't Take Them All"}], out],
    :json => [Representable::JSON, out="[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    describe "Module::for_collection [#{format}]" do
      let(:format) { format }

      let(:representer) {
        Module.new do
          include mod
          property :name#, :as => :title

          collection_representer :class => Song

          # self.representation_wrap = :songs if format == :xml
        end
      }

      it { render(songs.extend(representer.for_collection)).must_equal_document output }
      it { render(representer.for_collection.prepare(songs)).must_equal_document output }
      # parsing needs the class set, at least
      it { parse([].extend(representer.for_collection), input).must_equal songs }
    end

    describe "Module::for_collection without configuration [#{format}]" do
      let(:format) { format }

      let(:representer) {
        Module.new do
          include mod
          property :name
        end
      }

      # rendering works out of the box, no config necessary
      it { render(songs.extend(representer.for_collection)).must_equal_document output }
    end


    describe "Decorator::for_collection [#{format}]" do
      let(:format) { format }
      let(:representer) {
        Class.new(Representable::Decorator) do
          include mod
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.for_collection.new(songs)).must_equal_document output }
      it { parse(representer.for_collection.new([]), input).must_equal songs }
    end
  end
  # with module including module

  describe 'bad collections' do
    let(:representer) {
      Class.new(Representable::Decorator) do
        include Representable::Hash
        property :name

        collection_representer class: Song
      end
    }

    it 'parses when argument is an Array' do
      representer.for_collection.new([]).from_hash([{ 'name' => 'Gateways' }])
                 .must_equal [Song.new('Gateways')]
    end

    it 'parses when argument is a Hash' do
      representer.for_collection.new([]).from_hash('name' => 'Mother North')
                 .must_equal [Song.new('Mother North')]
    end

    it 'raises a TypeError when argument is not an Enumerable' do
      from_hash = -> {
        representer.for_collection.new([]).from_hash(nil)
      }.must_raise TypeError
      from_hash.message.must_equal 'Expected Enumerable, got NilClass.'

      from_hash = -> {
        representer.for_collection.new([]).from_hash('')
      }.must_raise TypeError
      from_hash.message.must_equal 'Expected Enumerable, got String.'
    end
  end
end
