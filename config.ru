$:.unshift File.expand_path('../lib', __FILE__)

require 'geminabox'

run Geminabox.gem_store("data")
