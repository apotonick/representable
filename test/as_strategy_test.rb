require 'test_helper'

class AsStrategyTest < BaseTest
  let(:format) { :hash }
  let(:song) { representer.prepare(Struct.new(:title).new('Revolution')) }

  class ReverseNamingStrategy
    def call(name)
      name.reverse
    end
  end

  describe 'module' do
    describe 'with lambda' do
      let(:output) { { 'TITLE' => 'Revolution' } }
      let(:input)  { { 'TITLE' => 'Wie es geht' } }

      representer! do
        self.naming_strategy = ->(name) { name.upcase }
        property :title
      end

      it { render(song).must_equal_document(output) }
      it { parse(song, input).title.must_equal('Wie es geht') }
    end

    describe 'with class responding to #call?' do
      let(:output) { { 'eltit' => 'Revolution' } }
      let(:input)  { { 'eltit' => 'Wie es geht' } }

      representer! do
        self.naming_strategy = ReverseNamingStrategy.new
        property :title
      end

      it { render(song).must_equal_document(output) }
      it { parse(song, input).title.must_equal('Wie es geht') }
    end

    describe 'with class not responding to #call?' do
      representer! do
        self.naming_strategy = Object.new
        property :title
      end

      it { -> { render(song) }.must_raise(RuntimeError) }
    end
  end

  describe 'decorator' do
    describe 'with a lambda' do
      let(:output) { { 'TITLE' => 'Revolution' } }
      let(:input)  { { 'TITLE' => 'Wie es geht' } }

      representer!(decorator: true) do
        self.naming_strategy = ->(name) { name.upcase }
        property :title
      end

      it { render(song).must_equal_document(output) }
      it { parse(song, input).title.must_equal('Wie es geht') }
    end
  end
end
