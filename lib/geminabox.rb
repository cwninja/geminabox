module Geminabox
  GemNotFound = Class.new(RuntimeError)
  BadGemfile = Class.new(RuntimeError)

  def self.gem_store(data_path)
    Geminabox::Server.new(data_path)
  end
end

require "geminabox/server"
require "geminabox/filename_generator"
require "geminabox/indexed_gem"
