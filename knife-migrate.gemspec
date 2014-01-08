$:.push File.expand_path('../lib', __FILE__)
require 'knife_migrate/version'

Gem::Specification.new do |gem|
  gem.name          = 'knife-migrate'
  gem.version       =  Knife::Migrate::VERSION
  gem.authors       = ["Case Commons"]
  gem.email         = 'pema@casecommons.org'
  gem.summary       = "Simple plugin to migrate environments using another environment"
  gem.description   = "It diffs two environments and provides options to update the an environment"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "knife-migrate"
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency 'chef', '>= 11.0.0'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-nav'
end
