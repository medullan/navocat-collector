# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'meda/version'

Gem::Specification.new do |spec|
  spec.name          = "meda"
  spec.version       = Meda::VERSION
  spec.authors       = ["Max Lord"]
  spec.email         = ["mlord@medullan.com"]
  spec.summary       = %q{Medullan analytics platform}
  spec.description   = %q{Medullan analytics, not for the masses}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "redis", "~> 3.0.1"
  spec.add_runtime_dependency "hiredis", "~> 0.4.5"
  spec.add_runtime_dependency "thor", "~> 0.18.1"
  spec.add_runtime_dependency "uuidtools", "~> 2.1.4"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "sinatra", "~> 1.4.4"
  spec.add_runtime_dependency "sinatra-contrib", "1.4.2"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdebug"
  spec.add_development_dependency "rspec", "~> 2.14.1"
  spec.add_development_dependency "rack-test", "~> 0.6.2"
end

