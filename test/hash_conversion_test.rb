# frozen_string_literal: true

require 'test_helper'
require 'representable/hash'

class HashConversionTest < MiniTest::Spec
  def payload
    {
      :title => '',
      'songs' => [{ 'title' => 't3' }, { 'title' => 't2' }],
      'band' => { :size => '', 'label' => { name: '', 'title': 'food' } },
      'producers' => [{ name: '' }]
    }
  end

  describe 'stringify_keys' do
    it 'convert keys' do
      new_hash = Representable::Hash::Conversion.stringify_keys(payload)
      assert new_hash.keys.all? { |k| k.is_a?(String) }
    end
    it 'convert nested keys' do
      new_hash = Representable::Hash::Conversion.stringify_keys(payload)
      assert new_hash['band'].keys.all? { |k| k.is_a?(String) }
      assert new_hash['band']['label'].keys.all? { |k| k.is_a?(String) }
    end
  end

  describe 'symbolize_keys' do
    it 'convert keys' do
      new_hash = Representable::Hash::Conversion.symbolize_keys(payload)
      assert new_hash.keys.all? { |k| k.is_a?(Symbol) }
    end
    it 'convert nested keys' do
      new_hash = Representable::Hash::Conversion.symbolize_keys(payload)
      puts new_hash
      assert new_hash[:band].keys.all? { |k| k.is_a?(Symbol) }
      assert new_hash[:band][:label].keys.all? { |k| k.is_a?(Symbol) }
    end
  end
end
