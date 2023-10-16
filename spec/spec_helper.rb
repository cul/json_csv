# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler'
Bundler.setup

require 'rspec'

def absolute_fixture_path(file)
  File.realpath(File.join(File.dirname(__FILE__), 'fixtures', file))
end

def fixture(file)
  path = absolute_fixture_path(file)
  raise "No fixture file at #{path}" unless File.exist? path

  File.new(path)
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
