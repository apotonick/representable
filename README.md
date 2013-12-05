# Representable

Representable maps ruby objects to documents and back.

In other words: Take an object and decorate it with a representer module. This will allow you to render a JSON, XML or YAML document from that object. But that's only half of it! You can also use representers to parse a document and create or populate an object.

Representable is helpful for all kind of rendering and parsing workflows. However, it is mostly useful in API code. Are you planning to write a real REST API with representable? Then check out the [roar](http://github.com/apotonick/roar) gem first, save work and time and make the world a better place instead.


## Installation

The representable gem is almost dependency-free. Almost.

```ruby
gem 'representable'
```

## Example

What if we're writing an API for music - songs, albums, bands.

```ruby
class Song < OpenStruct
end

song = Song.new(title: "Fallout", track: 1)
```

## Defining Representations

Representations are defined using representer modules.

```ruby
require 'representable/json'

module SongRepresenter
  include Representable::JSON

  property :title
  property :track
end
```

In the representer the #property method allows declaring represented attributes of the object. All the representer requires for rendering are readers on the represented object, e.g. `#title` and `#track`. When parsing, it will call setters - in our example, that'd be `#title=` and `#track=`.


## Rendering

Mixing in the representer into the object adds a rendering method.

```ruby
song.extend(SongRepresenter).to_json
#=> {"title":"Fallout","track":1}
```

## Parsing

It also adds support for parsing.

```ruby
song = Song.new.extend(SongRepresenter).from_json(%{ {"title":"Roxanne"} })
#=> #<Song title="Roxanne", track=nil>
```

## Extend vs. Decorator

If you don't want representer modules to be mixed into your objects (using `#extend`) you can use the `Decorator` strategy [described below](#decorator-vs-extend). Decorating instead of extending was introduced in 1.4.


## Aliasing

If your property name doesn't match the name in the document, use the `:as` option.

```ruby
module SongRepresenter
  include Representable::JSON

  property :title, as: :name
  property :track
end

song.to_json #=> {"name":"Fallout","track":1}
```


## Wrapping

Let the representer know if you want wrapping.

```ruby
module SongRepresenter
  include Representable::JSON

  self.representation_wrap= :hit

  property :title
  property :track
end
```

This will add a container for rendering and consuming.

```ruby
song.extend(SongRepresenter).to_json
#=> {"hit":{"title":"Fallout","track":1}}
```

Setting `self.representation_wrap = true` will advice representable to figure out the wrap itself by inspecting the represented object class.


## Collections

Let's add a list of composers to the song representation.

```ruby
module SongRepresenter
  include Representable::JSON

  property :title
  property :track
  collection :composers
end
```

Surprisingly, `#collection` lets us define lists of objects to represent.

```ruby
Song.new(title: "Fallout", composers: ["Steward Copeland", "Sting"]).
  extend(SongRepresenter).to_json

#=> {"title":"Fallout","composers":["Steward Copeland","Sting"]}
```

And again, this works both ways - in addition to the title it extracts the composers from the document, too.


## Nesting

Representers can also manage compositions. Why not use an album that contains a list of songs?

```ruby
class Album < OpenStruct
end

album = Album.new(name: "The Police", songs: [song, Song.new(title: "Synchronicity")])
```

Here comes the representer that defines the composition.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs, extend: SongRepresenter, class: Song
end
```

Note that nesting works with both plain `#property` and `#collection`.

When rendering, the `:extend` module is used to extend the attribute(s) with the correct representer module.

```ruby
album.extend(AlbumRepresenter).to_json
#=> {"name":"The Police","songs":[{"title":"Fallout","composers":["Steward Copeland","Sting"]},{"title":"Synchronicity","composers":[]}]}
```

Parsing a documents needs both `:extend` and the `:class` option as the parser requires knowledge what kind of object to create from the nested composition.

```ruby
Album.new.extend(AlbumRepresenter).
  from_json(%{{"name":"Offspring","songs":[{"title":"Genocide"},{"title":"Nitro","composers":["Offspring"]}]}})

#=> #<Album name="Offspring", songs=[#<Song title="Genocide">, #<Song title="Nitro", composers=["Offspring"]>]>
```

## Syncing Objects

Usually, representable creates a new nested object when parsing. If you want to update an existing object, use the `parse_strategy` option.

```ruby
module AlbumRepresenter
  include Representable::JSON

  collection :songs, extend: SongRepresenter, parse_strategy: :sync
```

When parsing an album, it will now call `from_json` on the existing songs in the collection.

```ruby
album = Album.find(1)
album.songs.first #=> #<Song:0x999 title: "Panama">
```

Note that the album already contains a song instance.

```ruby
album.extend(AlbumRepresenter).
  from_json('{songs: [{title: "Eruption"}]}')

album.songs.first #=> #<Song:0x999 title: "Eruption">
```

Now, representable didn't create a new `Song` instance but updated the existing, resulting in renaming the song.

## Inline Representers

If you don't want to maintain two separate modules when nesting representations you can define the `SongRepresenter` inline.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name

  collection :songs, class: Song do
    property :title
    property :track
    collection :composers
  end
```

This works both for representer modules and decorators.

You can use an inline representer along with `:extend`. The latter will automatically be included in the inline representer. This is handy if you want to inline-extend a base decorator.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :hit, extend: SongRepresenter do
    property :numbers_sold
  end
```

## Decorator vs. Extend

People who dislike `:extend` go use the `Decorator` strategy!

```ruby
class SongRepresentation < Representable::Decorator
  include Representable::JSON

  property :title
  property :track
end
```

The `Decorator` constructor requires the represented object.

```ruby
SongRepresentation.new(song).to_json
```

This will leave the `song` instance untouched as the decorator just uses public accessors to represent the hit.

In compositions you need to specify the decorators for the nested items using the `:decorator` option where you'd normally use `:extend`.

```ruby
class AlbumRepresentation < Representable::Decorator
  include Representable::JSON

  collection :songs, :class => Song, :decorator => SongRepresentation
end
```

### Helpers In Decorators

In module representers you can add methods for properties.

```ruby
module SongRepresenter
  property :title

  def title
    @name
  end
```

That works as the method is mixed into the represented object. When adding a helper method to a decorator, representable will still invoke accessors on the represented instance - unless you tell it the scope.

```ruby
class SongRepresenter < Representable::Decorator
  property :title, decorator_scope: true

  def title
    represented.name
  end
end
```

This will call `title` getter and setter on the decorator instance, not on the represented object. You can still access the represented object in the decorator method using `represented`. BTW, in a module representer this option is ignored.

Or use `:getter` or `:setter` to dynamically add a method for the represented object.

```ruby
class SongRepresenter < Representable::Decorator
  property :title, getter: lambda { |*| @name }
```
As always, the block is executed in the represented object's context.

## XML Support

While representable does a great job with JSON, it also features support for XML, YAML and pure ruby hashes.

```ruby
require 'representable/xml'

module SongRepresenter
  include Representable::XML

  property :title
  property :track
  collection :composers
end
```

For XML we just include the `Representable::XML` module.

```xml
Song.new(title: "Fallout", composers: ["Steward Copeland", "Sting"]).
     extend(SongRepresenter).to_xml #=>
<song>
    <title>Fallout</title>
    <composers>Steward Copeland</composers>
    <composers>Sting</composers>
</song>
```

## Passing Options

You're free to pass an options hash into the rendering or parsing.

```ruby
song.to_json(:append => "SOLD OUT!")
```

If you want to append the "SOLD OUT!" to the song's `title` when rendering, use the `:getter` option.

```ruby
SongRepresenter
  include Representable::JSON

  property :title, :getter => lambda { |args| title + args[:append] }
end
```

Note that the block is executed in the represented model context which allows using accessors and instance variables.


The same works for parsing using the `:setter` method.

```ruby
property :title, :setter => lambda { |val, args| self.title= val + args[:append] }
```

Here, the block retrieves two arguments: the parsed value and your user options.

You can also use the `:getter` option instead of writing a reader method. Even when you're not interested in user options you can still use this technique.

```ruby
property :title, :getter => lambda { |*| @name }
```

This hash will also be available in the `:if` block, documented [here](https://github.com/apotonick/representable/#conditions) and will be passed to nested objects.

## Using Helpers

Sometimes it's useful to override accessors to customize output or parsing.

```ruby
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
```

Note how the representer allows calling `super` in order to access the original attribute method of the represented object.

To change the parsing process override the setter.

```ruby
def name=(value)
  super(value.downcase)
end
```

## Inheritance

To reuse existing representers you can inherit from those modules.

```ruby
module CoverSongRepresenter
  include Representable::JSON
  include SongRepresenter

  property :copyright
end
```

Inheritance works by `include`ing already defined representers.

```ruby
Song.new(:title => "Truth Hits Everybody", :copyright => "The Police").
  extend(CoverSongRepresenter).to_json

#=> {"title":"Truth Hits Everybody","copyright":"The Police"}
```

## Overriding Properties

You might want to override a particular property in an inheriting representer. Successively calling `property(name)` will override the former definition for `name` just as you know it from overriding methods.

```ruby
module CoverSongRepresenter
  include Representable::JSON

  include SongRepresenter        # defines property :title
  property :title, as: :known_as # overrides that definition.
end
```

This behaviour was added in 1.7.


## Polymorphic Extend

Sometimes heterogenous collections of objects from different classes must be represented. Or you don't know which representer to use at compile-time and need to delay the computation until runtime. This is why `:extend` accepts a lambda, too.

Given we not only have songs, but also cover songs.

```ruby
class CoverSong < Song
end
```

And a non-homogenous collection of songs.

```ruby
songs = [ Song.new(title: "Weirdo", track: 5),
          CoverSong.new(title: "Truth Hits Everybody", track: 6, copyright: "The Police")]

album = Album.new(name: "Incognito", songs: songs)
```

The `CoverSong` instances are to be represented by their very own `CoverSongRepresenter` defined above. We can't just use a static module in the `:extend` option, so go use a dynamic lambda!

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs, :extend => lambda { |song, *| song.is_a?(CoverSong) ? CoverSongRepresenter : SongRepresenter }
end
```

Note that the lambda block is evaluated in the represented object context which allows to access helpers or whatever in the block. This works for single properties, too.


## Polymorphic Object Creation

Rendering heterogenous collections usually implies that you also need to parse those. Luckily, `:class` also accepts a lambda.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs,
    :extend => ...,
    :class  => lambda { |hsh, *| hsh.has_key?("copyright") ? CoverSong : Song }
end
```

The block for `:class` receives the currently parsed fragment. Here, this might be somthing like `{"title"=>"Weirdo", "track"=>5}`.

If this is not enough, you may override the entire object creation process using `:instance`.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs,
    :extend   => ...,
    :instance => lambda { |hsh, *| hsh.has_key?("copyright") ? CoverSong.new : Song.new(original: true) }
end
```

## Hashes

As an addition to single properties and collections representable also offers to represent hash attributes.

```ruby
module SongRepresenter
  include Representable::JSON

  property :title
  hash :ratings
end

Song.new(title: "Bliss", ratings: {"Rolling Stone" => 4.9, "FryZine" => 4.5}).
extend(SongRepresenter).to_json

#=> {"title":"Bliss","ratings":{"Rolling Stone":4.9,"FryZine":4.5}}
```

## Lonely Hashes

Need to represent a bare hash without any container? Use the `JSON::Hash` representer (or XML::Hash).

```ruby
require 'representable/json/hash'

module FavoriteSongsRepresenter
  include Representable::JSON::Hash
end

{"Nick" => "Hyper Music", "El" => "Blown In The Wind"}.extend(FavoriteSongsRepresenter).to_json
#=> {"Nick":"Hyper Music","El":"Blown In The Wind"}
```

Works both ways. The values are configurable and might be self-representing objects in turn. Tell the `Hash` by using `#values`.

```ruby
module FavoriteSongsRepresenter
  include Representable::JSON::Hash

  values extend: SongRepresenter, class: Song
end

{"Nick" => Song.new(title: "Hyper Music")}.extend(FavoriteSongsRepresenter).to_json
```

In XML, if you want to store hash attributes in tag attributes instead of dedicated nodes, use `XML::AttributeHash`.

## Lonely Collections

Same goes with arrays.

```ruby
require 'representable/json/collection'

module SongsRepresenter
  include Representable::JSON::Collection

  items extend: SongRepresenter, class: Song
end
```

The `#items` method lets you configure the contained entity representing here.

```ruby
[Song.new(title: "Hyper Music"), Song.new(title: "Screenager")].extend(SongsRepresenter).to_json
#=> [{"title":"Hyper Music"},{"title":"Screenager"}]
```

Note that this also works for XML.


## YAML Support

Representable also comes with a YAML representer.

```ruby
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers, :style => :flow
end
```

A nice feature is that `#collection` also accepts a `:style` option which helps having nicely formatted inline (or "flow") arrays in your YAML - if you want that!

```ruby
song.extend(SongRepresenter).to_yaml
#=>
---
title: Fallout
composers: [Steward Copeland, Sting]
```

## More on XML

### Mapping Tag Attributes

You can also map properties to tag attributes in representable. This works only for the top-level node, thou (seen from the representer's perspective).

```ruby
module SongRepresenter
  include Representable::XML

  property :title, attribute: true
  property :track, attribute: true
end

Song.new(title: "American Idle").to_xml
#=> <song title="American Idle" />
```

Naturally, this works for both ways.


### Mapping Content

The same concept can also be applied to content. If you need to map a property to the top-level node's content, use the `:content` option. Again, _top-level_ refers to the document fragment that maps to the representer.

```ruby
module SongRepresenter
  include Representable::XML

  property :title, content: true
end

Song.new(title: "American Idle").to_xml
#=> <song>American Idle</song>
```


### Wrapping Collections

It is sometimes unavoidable to wrap tag lists in a container tag.

```ruby
module AlbumRepresenter
  include Representable::XML

  collection :songs, :as => :song, :wrap => :songs
end
```

Note that `:wrap` defines the container tag name.

```xml
Album.new.to_xml #=>
<album>
    <songs>
        <song>Laundry Basket</song>
        <song>Two Kevins</song>
        <song>Wright and Rong</song>
    </songs>
</album>
```

### Namespaces

Support for namespaces are not yet implemented. However, if an incoming parsed document contains namespaces, you can automatically remove them.

```ruby
module AlbumRepresenter
  include Representable::XML

  remove_namespaces!
```

## Avoiding Modules

There's been a rough discussion whether or not to use `extend` in Ruby. If you want to save that particular step when representing objects, define the representers right in your classes.

```ruby
class Song < OpenStruct
  include Representable::JSON

  property :name
end
```

I do not recommend this approach as it bloats your domain classes with representation logic that is barely needed elsewhere. Use [decorators](#decorator-vs-extend) instead.


## More Options

Here's a quick overview about other available options for `#property` and its bro `#collection`.


### Overriding Read And Write

This can be handy if a property needs to be compiled from several fragments. The lambda has access to the entire object document (either hash or `Nokogiri` node) and user options.

```ruby
property :title, :writer => lambda { |doc, args| doc["title"] = title || original_title }
```

When using the `:writer` option it is up to you to add fragments to the `doc` - representable won't add anything for this property.

The same works for parsing using `:reader`.

```ruby
property :title, :reader => lambda { |doc, args| self.title = doc["title"] || doc["name"] }
```

### Read/Write Restrictions

Using the `:readable` and `:writeable` options access to properties can be restricted.

```ruby
property :title, :readable => false
```

This will leave out the `title` property in the rendered document. Vice-versa, `:writeable` will skip the property when parsing and does not assign it.


### Filtering

Representable also allows you to skip and include properties using the `:exclude` and `:include` options passed directly to the respective method.

```ruby
song.to_json(:include => :title)
#=> {"title":"Roxanne"}
```

### Conditions

You can also define conditions on properties using `:if`, making them being considered only when the block returns a true value.

```ruby
module SongRepresenter
  include Representable::JSON

  property :title
  property :track, if: lambda { track > 0 }
end
```

When rendering or parsing, the `track` property is considered only if track is valid. Note that the block is executed in instance context, giving you access to instance methods.

As always, the block retrieves your options. Given this render call

```ruby
song.to_json(minimum_track: 2)
```

your `:if` may process the options.

```ruby
property :track, if: lambda { |opts| track > opts[:minimum_track] }
```

### False and Nil Values

Since representable-1.2 `false` values _are_ considered when parsing and rendering. That particularly means properties that used to be unset (i.e. `nil`) after parsing might be `false` now. Vice versa, `false` properties that weren't included in the rendered document will be visible now.

If you want `nil` values to be included when rendering, use the `:render_nil` option.

```ruby
property :track, render_nil: true
```

## Coercion

If you fancy coercion when parsing a document you can use the Coercion module which uses [virtus](https://github.com/solnic/virtus) for type conversion.

Include virtus in your Gemfile, first. Be sure to include virtus 0.5.0 or greater.

```ruby
gem 'virtus', ">= 0.5.0"
```

Use the `:type` option to specify the conversion target. Note that `:default` still works.

```ruby
module SongRepresenter
  include Representable::JSON
  include Representable::Coercion

  property :title
  property :recorded_at, :type => DateTime, :default => "May 12th, 2012"
end
```

In a decorator it works alike.

```ruby
module SongRepresenter < Representable::Decorator
  include Representable::JSON
  include Representable::Coercion

  property :recorded_at, :type => DateTime
end
```

Coercing values only happens when rendering or parsing a document. Representable does not create accessors in your model as `virtus` does.

## Undocumented Features

*(Please don't read this section!)*

#### If you need a special binding for a property you're free to create it using the `:binding` option.

<!-- here comes some code -->
```ruby
property :title, :binding => lambda { |*args| JSON::TitleBinding.new(*args) }
```

#### You can use the parsed document fragment directly as a representable instance by returning `nil` in `:class`.

<!-- here comes some code -->
```ruby
property :song, :class => lambda { |*| nil }
```

This makes sense when your parsing looks like this.

<!-- here comes some code -->
```ruby
hit.from_hash(song: <#Song ..>)
```

Representable will not attempt to create a `Song` instance for you but use the provided from the document.

#### The same goes the other way when rendering. Just provide an empty `:instance` block.

<!-- here comes some code -->
```ruby
property :song, :instance => lambda { |*| nil }
```

This will treat the `song` property instance as a representable object.

<!-- here comes some code -->
```ruby
hit.to_json # this will call hit.song.to_json
```

Rendering `collection`s works the same. Parsing doesn't work out-of-the-box, currently, as we're still unsure how to map items to fragments.

## Copyright

Representable started as a heavily simplified fork of the ROXML gem. Big thanks to Ben Woosley for his inspiring work.

* Copyright (c) 2011-2013 Nick Sutterer <apotonick@gmail.com>
* ROXML is Copyright (c) 2004-2009 Ben Woosley, Zak Mandhro and Anders Engstrom.

Representable is released under the [MIT License](http://www.opensource.org/licenses/MIT).
