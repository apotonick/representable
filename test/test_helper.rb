require 'bundler'
Bundler.setup

gem 'minitest' # ensures you're using the gem, and not the built in MT
require 'minitest/spec'
require 'minitest/autorun'

require 'representable'
require 'test_xml/mini_test'
require 'mocha'
