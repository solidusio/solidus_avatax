# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "solidus_avatax"
  s.version     = "2.0.0.alpha"
  s.summary     = "Avatax extension for Solidus"
  s.description = "Solidus extension to retrieve tax rates via Avalara's SOAP API."
  s.required_ruby_version = ">= 2.1"

  s.author       = "Solidus Team"
  s.email        = "contact@solidus.io"
  s.homepage     = "https://solidus.io"
  s.license      = %q{BSD-3}

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = "lib"
  s.requirements << "none"

  s.add_dependency "solidus_core", ">= 1.3.0.alpha", "< 1.4"
  s.add_dependency "hashie",      ">= 3"
  s.add_dependency "multi_json"
  s.add_dependency "Avatax_TaxService", "~> 2.0.0"

  s.add_development_dependency "rspec-rails","~> 3.2"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "sass-rails"
  s.add_development_dependency "coffee-rails"
  s.add_development_dependency "factory_girl", "~> 4.2"
  s.add_development_dependency "capybara", "~> 2.1"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "ffaker"
end
