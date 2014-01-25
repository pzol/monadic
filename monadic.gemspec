# -*- encoding: utf-8 -*-
require File.expand_path('../lib/monadic/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Piotr Zolnierek"]
  gem.email         = ["pz@anixe.pl"]
  gem.description   = %q{brings some functional goodness to ruby by giving you some monads}
  gem.summary       = %q{see README}
  gem.homepage      = "http://github.com/pzol/monadic"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "monadic"
  gem.require_paths = ["lib"]
  gem.version       = Monadic::VERSION

  gem.add_development_dependency 'rspec', '>=2.9.0'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'guard-bundler'
  gem.add_development_dependency 'growl'
  gem.add_development_dependency 'activesupport'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rb-fsevent', '~> 0.9.1'
end
