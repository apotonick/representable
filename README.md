# Representable

Representable maps ruby objects to documents and back.

In other words: Take an object and extend it with a representer module. This will allow you to render a JSON, XML or YAML document from that object. But that's only half of it! You can also use representers to parse a document and create an object.

Representable is helpful for all kind of rendering and parsing workflows. However, it is mostly useful in API code. Are you planning to write a real REST API with representable? Then check out the [roar](http://github.com/apotonick/roar) gem first, save work and time and make the world a better place instead.


## Installation

The representable gem is almost dependency-free. Almost.

    gem 'representable'


## Example

What if we're writing an API for music - songs, albums, bands.

    class Song < OpenStruct
    end

    song = Song.new(title: "Fallout", track: 1)


## Defining Representations

Representations are defined using representer modules.

    require 'representable/json'

    module SongRepresenter
      include Representable::JSON

      property :title
      property :track
    end

In the representer the #property method allows declaring represented attributes of the object. All the representer requires for rendering are readers on the represented object, e.g. `#title` and `#track`. When parsing, it will call setters - in our example, that'd be `#title=` and `#track=`.


## Rendering

Mixing in the representer into the object adds a rendering method.

    song.extend(SongRepresenter).to_json
    #=> {"title":"Fallout","track":1}


## Parsing

It also adds support for parsing.

    song = Song.new.extend(SongRepresenter).from_json(%{ {"title":"Roxanne"} })
    #=> #<Song title="Roxanne", track=nil>


## Wrapping

Let the representer know if you want wrapping.

    module SongRepresenter
      include Representable::JSON

      self.representation_wrap= :hit

      property :title
      property :track
    end

This will add a container for rendering and consuming.

    song.extend(SongRepresenter).to_json
    #=> {"hit":{"title":"Fallout","track":1}}

Setting `self.representation_wrap = true` will advice representable to figure out the wrap itself by inspecting the represented object class.


## Collections

Let's add a list of composers to the song representation.

    module SongRepresenter
      include Representable::JSON

      property :title
      property :track
      collection :composers
    end

Surprisingly, `#collection` lets us define lists of objects to represent.

    Song.new(title: "Fallout", composers: ["Steward Copeland", "Sting"]).
      extend(SongRepresenter).to_json

    #=> {"title":"Fallout","composers":["Steward Copeland","Sting"]}


And again, this works both ways - in addition to the title it extracts the composers from the document, too.


## Nesting

Representers can also manage compositions. Why not use an album that contains a list of songs?

    class Album < OpenStruct
    end

    album = Album.new(name: "The Police", songs: [song, Song.new(title: "Synchronicity")])


Here comes the representer that defines the composition.

    module AlbumRepresenter
      include Representable::JSON

      property :name
      collection :songs, extend: SongRepresenter, class: Song
    end

Note that nesting works with both plain `#property` and `#collection`.

When rendering, the `:extend` module is used to extend the attribute(s) with the correct representer module.

    album.extend(AlbumRepresenter).to_json
    #=> {"name":"The Police","songs":[{"title":"Fallout","composers":["Steward Copeland","Sting"]},{"title":"Synchronicity","composers":[]}]}

Parsing a documents needs both `:extend` and the `:class` option as the parser requires knowledge what kind of object to create from the nested composition.

    Album.new.extend(AlbumRepresenter).
      from_json(%{{"name":"Offspring","songs":[{"title":"Genocide"},{"title":"Nitro","composers":["Offspring"]}]}})

    #=> #<Album name="Offspring", songs=[#<Song title="Genocide">, #<Song title="Nitro", composers=["Offspring"]>]>


## XML Support

While representable does a great job with JSON, it also features support for XML, YAML and pure ruby hashes.

    require 'representable/xml'

    module SongRepresenter
      include Representable::XML

      property :title
      property :track
      collection :composers
    end

For XML we just include the `Representable::XML` module.

    Song.new(title: "Fallout", composers: ["Steward Copeland", "Sting"]).
      extend(SongRepresenter).to_xml

    #=> <song>
          <title>Fallout</title>
          <composers>Steward Copeland</composers>
          <composers>Sting</composers>
        </song>


## Using Helpers

Sometimes it's useful to override accessors to customize output or parsing.

    module AlbumRepresenter
      include Representable::JSON
      
      property :name
      collection :songs

      def name
        super.upcase
      end
    end

    Album.new(:name => "The Police").
      extend(AlbumRepresenter).to_json

    #=> {"name":"THE POLICE","songs":[]}

Note how the representer allows calling `super` in order to access the original attribute method of the represented object.

To change the parsing process override the setter.

      def name=(value)
        super(value.downcase)
      end


## Inheritance

To reuse existing representers you can inherit from those modules.

    module CoverSongRepresenter
      include Representable::JSON
      include SongRepresenter

      property :copyright
    end

Inheritance works by `include`ing already defined representers.

    Song.new(:title => "Truth Hits Everybody", :copyright => "The Police").
      extend(CoverSongRepresenter).to_json

    #=> {"title":"Truth Hits Everybody","copyright":"The Police"}


## Polymorphic Extend

Sometimes heterogenous collections of objects from different classes must be represented. Or you don't know which representer to use at compile-time and need to delay the computation until runtime. This is why `:extend` accepts a lambda, too.

Given we not only have songs, but also cover songs.

    class CoverSong < Song
    end

And a non-homogenous collection of songs.

    songs = [ Song.new(title: "Weirdo", track: 5), 
              CoverSong.new(title: "Truth Hits Everybody", track: 6, copyright: "The Police")]
    
    album = Album.new(name: "Incognito", songs: songs)


The `CoverSong` instances are to be represented by their very own `CoverSongRepresenter` defined above. We can't just use a static module in the `:extend` option, so go use a dynamic lambda!

    module AlbumRepresenter
      include Representable::JSON

      property :name
      collection :songs, :extend => lambda { |song| song.is_a?(CoverSong) ? CoverSongRepresenter : SongRepresenter }
    end

Note that the lambda block is evaluated in the represented object context which allows to access helpers or whatever in the block. This works for single properties, too.


## Polymorphic Object Creation

Rendering heterogenous collections usually implies that you also need to parse those. Luckily, `:class` also accepts a lambda.

    module AlbumRepresenter
      include Representable::JSON

      property :name
      collection :songs, 
        :extend => ...,
        :class  => lambda { |hsh| hsh.has_key?("copyright") ? CoverSong : Song }
    end

The block for `:class` receives the currently parsed fragment. Here, this might be somthing like `{"title"=>"Weirdo", "track"=>5}`.

If this is not enough, you may override the entire object creation process using `:instance`.

    module AlbumRepresenter
      include Representable::JSON

      property :name
      collection :songs, 
        :extend   => ...,
        :instance => lambda { |hsh| hsh.has_key?("copyright") ? CoverSong.new : Song.new(original: true) }
    end


## Hashes

As an addition to single properties and collections representable also offers to represent hash attributes.
    
    module SongRepresenter
      include Representable::JSON

      property :title
      hash :ratings
    end

    Song.new(title: "Bliss", ratings: {"Rolling Stone" => 4.9, "FryZine" => 4.5}).
    extend(SongRepresenter).to_json
    
    #=> {"title":"Bliss","ratings":{"Rolling Stone":4.9,"FryZine":4.5}}


## Lonely Hashes

Need to represent a bare hash without any container? Use the `JSON::Hash` representer (or XML::Hash).

    require 'representable/json/hash'

    module FavoriteSongsRepresenter
      include Representable::JSON::Hash
    end

    {"Nick" => "Hyper Music", "El" => "Blown In The Wind"}.extend(FavoriteSongsRepresenter).to_json
    #=> {"Nick":"Hyper Music","El":"Blown In The Wind"}

Works both ways. The values are configurable and might be self-representing objects in turn. Tell the `Hash` by using `#values`.

    module FavoriteSongsRepresenter
      include Representable::JSON::Hash

      values extend: SongRepresenter, class: Song
    end

    {"Nick" => Song.new(title: "Hyper Music")}.extend(FavoriteSongsRepresenter).to_json

 In XML, if you want to store hash attributes in tag attributes instead of dedicated nodes, use `XML::AttributeHash`.

## Lonely Collections

Same goes with arrays.

    require 'representable/json/collection'

    module SongsRepresenter
      include Representable::JSON::Collection

      items extend: SongRepresenter, class: Song
    end

The `#items` method lets you configure the contained entity representing here.

    [Song.new(title: "Hyper Music"), Song.new(title: "Screenager")].extend(SongsRepresenter).to_json
    #=> [{"title":"Hyper Music"},{"title":"Screenager"}]

Note that this also works for XML.


## YAML Support

Representable also comes with a YAML representer.

    module SongRepresenter
      include Representable::YAML

      property :title
      property :track
      collection :composers, :style => :flow
    end

A nice feature is that `#collection` also accepts a `:style` option which helps having nicely formatted inline (or "flow") arrays in your YAML - if you want that!

    song.extend(SongRepresenter).to_yaml
    #=>
    ---
    title: Fallout
    composers: [Steward Copeland, Sting]


## More on XML

### Mapping tag attributes

You can also map properties to tag attributes in representable.

    module SongRepresenter
      include Representable::XML

      property :title, attribute: true
      property :track, attribute: true
    end
    
    Song.new(title: "American Idle").to_xml
    #=> <song title="American Idle" />

Naturally, this works for both ways.

### Wrapping collections

It is sometimes unavoidable to wrap tag lists in a container tag.

    module AlbumRepresenter
      include Representable::XML

      collection :songs, :as => :song, :wrap => :songs
    end

Note that `:wrap` defines the container tag name.

    Album.new.to_xml #=> 
      <album>
        <songs>
          <song>Laundry Basket</song>
          <song>Two Kevins</song>
          <song>Wright and Rong</song>
        </songs>
      </album>


## Avoiding Modules

There's been a rough discussion whether or not to use `extend` in Ruby. If you want to save that particular step when representing objects, define the representers right in your classes.

    class Song < OpenStruct
      include Representable::JSON

      property :name
    end

I do not recommend this approach as it bloats your domain classes with representation logic that is barely needed elsewhere.


## More Options

Here's a quick overview about other available options for `#property` and its bro `#collection`.


### Read/Write Restrictions

Using the `:readable` and `:writeable` options access to properties can be restricted.

    property :title, :readable => false

This will leave out the `title` property in the rendered document. Vice-versa, `:writeable` will skip the property when parsing and does not assign it.


### Filtering

Representable also allows you to skip and include properties using the `:exclude` and `:include` options passed directly to the respective method.

    song.to_json(:include => :title)
    #=> {"title":"Roxanne"}


### Conditions

You can also define conditions on properties using `:if`, making them being considered only when the block returns a true value.

    module SongRepresenter
      include Representable::JSON

      property :title
      property :track, if: lambda { track > 0 }
    end
  
When rendering or parsing, the `track` property is considered only if track is valid. Note that the block is executed in instance context, giving you access to instance methods.


### Mapping

If your property name doesn't match the attribute name in the document, use the `:as` option.

    module SongRepresenter
      property :title
      property :track, as: :track_number
    end
    
    song.to_json #=> {"title":"Superstars","track_number":1}


### False and Nil Values

Since representable-1.2 `false` values _are_ considered when parsing and rendering. That particularly means properties that used to be unset (i.e. `nil`) after parsing might be `false` now. Vice versa, `false` properties that weren't included in the rendered document will be visible now.

If you want `nil` values to be included when rendering, use the `:render_nil` option.

    property :track, render_nil: true

## Coercion

If you fancy coercion when parsing a document you can use the Coercion module which uses [virtus](https://github.com/solnic/virtus) for type conversion.

Include virtus in your Gemfile, first. Be sure to include virtus 0.5.0 or greater.

    gem 'virtus', ">= 0.5.0"

Use the `:type` option to specify the conversion target. Note that `:default` still works.

    module SongRepresenter
      include Representable::JSON
      include Virtus
      include Representable::Coercion
      
      property :title
      property :recorded_at, :type => DateTime, :default => "May 12th, 2012"
    end


## Copyright

Representable started as a heavily simplified fork of the ROXML gem. Big thanks to Ben Woosley for his inspiring work.

* Copyright (c) 2011-2013 Nick Sutterer <apotonick@gmail.com>
* ROXML is Copyright (c) 2004-2009 Ben Woosley, Zak Mandhro and Anders Engstrom.
