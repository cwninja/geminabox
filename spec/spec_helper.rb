require 'simplecov'
SimpleCov.start

require 'bundler'

$:.unshift File.expand_path('../lib', __FILE__)
require "geminabox"

Bundler.with_clean_env do
  version = IO.popen(['gem', '--version'], &:read).chomp
  puts "RubyGems version: #{version}"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "spec/.rspec-status.txt"
  config.disable_monkey_patching!
  #config.warnings = true
  #config.profile_examples = 10
  config.order = :random

  Kernel.srand config.seed

  if config.files_to_run.one?
    config.default_formatter = 'doc'
    config.profile_examples = false
  end
end

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each do |f|
  require f
end
