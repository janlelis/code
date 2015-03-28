# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/code/version"

Gem::Specification.new do |gem|
  gem.name          = "code"
  gem.version       = Code::VERSION
  gem.summary       = "Displays a method's code."
  gem.description   = "Displays a method's code (from source or docs)."
  gem.authors       = ["Jan Lelis"]
  gem.email         = "mail@janlelis.de"
  gem.homepage      = "https://github.com/janlelis/code"
  gem.license       = "MIT"

  gem.files         = Dir['{**/}{.*,*}'].select{ |path| File.file?(path) && path !~ /^pkg/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = "~> 2.0"
  gem.add_dependency "method_source", "~> 0.8", ">= 0.8.2"
  gem.add_dependency "coderay", "~> 1.1"
end
