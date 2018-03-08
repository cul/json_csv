require File.expand_path("../lib/json_csv/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'json_csv'
  s.version     = JsonCsv::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = '2018-02-18'
  s.summary     = "A library for converting json to csv...and back!"
  s.description = "A library for converting json to csv...and back!"
  s.authors     = ["Eric O'Hanlon"]
  s.email       = 'elo2112@columbia.edu'
  s.homepage    = 'https://github.com/cul/json_csv'
  s.license     = 'MIT'

  s.add_development_dependency("rake", ">= 10.1")
  s.add_development_dependency("rspec", "~>3.7")
  s.add_development_dependency("rubocop", "~> 0.51.0")
  s.add_development_dependency("rubocop-rspec", "~> 1.20.1")
  s.add_development_dependency("simplecov", "~> 0.15.1")

  s.files        = Dir["lib/**/*.rb", "lib/tasks/**/*.rake", "bin/*", "LICENSE", "*.md"]
  s.require_paths = ['lib']
end
