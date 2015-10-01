require 'representable'
require 'representable/json'
require 'representable/xml'
require 'representable/yaml'
require 'minitest/autorun'
require 'test_xml/mini_test'

class Album
  attr_accessor :songs, :best_song
  def initialize(songs=nil, best_song=nil)
    @songs      = songs
    @best_song  = best_song
  end

  def ==(other)
    songs == other.songs and best_song == other.best_song
  end
end

class Song
  attr_accessor :name, :track # never change this, track rendered with Rails#to_json.
  def initialize(name=nil, track=nil)
    @name   = name
    @track  = track
  end

  def ==(other)
    name == other.name and track == other.track
  end
end

module XmlHelper
  def xml(document)
    Nokogiri::XML(document).root
  end
end

module AssertJson
  module Assertions
    def assert_json(expected, actual, msg=nil)
      msg = message(msg, "") { diff expected, actual }
      assert(expected.split("").sort == actual.split("").sort, msg)
    end
  end
end

MiniTest::Spec.class_eval do
  include AssertJson::Assertions
  include XmlHelper

  def self.for_formats(formats)
    formats.each do |format, cfg|
      mod, output, input = cfg
      yield format, mod, output, input
    end
  end

  def render(object, *args)
    AssertableDocument.new(object.send("to_#{format}", *args), format)
  end

  def parse(object, input, *args)
    object.send("from_#{format}", input, *args)
  end

  class AssertableDocument
    attr_reader :document

    def initialize(document, format)
      @document, @format = document, format
    end

    def must_equal_document(*args)
      return document.must_equal_xml(*args) if @format == :xml
      document.must_equal(*args)
    end
  end

  def self.representer!(options={}, &block)
    fmt = options # we need that so the 2nd call to ::let (within a ::describe) remembers the right format.

    name   = options[:name]   || :representer
    format = options[:module] || Representable::Hash

    let(name) do
      mod = options[:decorator] ? Class.new(Representable::Decorator) : Module.new

      inject_representer(mod, fmt)

      mod.module_eval do
        include format
        instance_exec(&block)
      end

      mod
    end

    def inject_representer(mod, options)
      return unless options[:inject]

      injected_name = options[:inject]
      injected = send(injected_name) # song_representer
      mod.singleton_class.instance_eval do
        define_method(injected_name) { injected }
      end
    end
  end

  module TestMethods
    def representer_for(modules=[Representable::Hash], &block)
      Module.new do
        extend TestMethods
        include *modules
        module_exec(&block)
      end
    end

    alias_method :representer!, :representer_for
  end
  include TestMethods
end

class BaseTest < MiniTest::Spec
  let (:new_album)  { OpenStruct.new.extend(representer) }
  let (:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  let (:song) { OpenStruct.new(:title => "Resist Stance") }
  let (:song_representer) { Module.new do include Representable::Hash; property :title end  }

end

$print_profiler = false

case RUBY_ENGINE
when "ruby"
  require 'ruby-prof'
  def profile
    RubyProf.start
    yield
    res = RubyProf.stop
    printer = RubyProf::FlatPrinter.new(res)
    printer.print STDOUT if $print_profiler
    data = StringIO.new
    printer.print data
    data.string
  end
  def build_match count, klass
    "#{count}   #{klass}"
  end
when "rbx"
  require 'rubinius/profiler'
  def profile
    profiler = Rubinius::Profiler::Instrumenter.new
    profiler.start
    yield
    profiler.stop
    profiler.show if $print_profiler
    data = StringIO.new
    profiler.show data
    data.string
  end
  def build_match count, klass
    %r(#{count}\s*[0-9.]*\s*[0-9.]*\s*#{klass})
  end
end
