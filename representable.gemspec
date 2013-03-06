# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'representable/version'

Gem::Specification.new do |s|
  s.name        = "representable"
  s.version     = Representable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nick Sutterer"]
  s.email       = ["apotonick@gmail.com"]
  s.homepage    = "http://representable.apotomo.de"
  s.summary     = %q{Maps representation documents from and to Ruby objects. Includes XML and JSON support, plain properties, collections and compositions.}
  s.description = %q{Maps representation documents from and to Ruby objects. Includes XML and JSON support, plain properties, collections and compositions.}
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "nokogiri"
  s.add_dependency "multi_json"

  s.add_development_dependency "rake"
  s.add_development_dependency "test_xml"
  s.add_development_dependency "minitest", ">= 2.8.1"
  s.add_development_dependency "mocha", ">= 0.13.0"
  s.add_development_dependency "mongoid"
  s.add_development_dependency "virtus", "~> 0.5.0"
  s.add_development_dependency "yajl-ruby"
end
