# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'meda/version'

Gem::Specification.new do |spec|
  spec.name          = "meda"
  spec.version       = Meda::VERSION
  spec.authors       = ['Max Lord','Sheldon Hall']
  spec.email         = ["shall@medullan.com"]
  spec.summary       = %q{Medullan analytics platform}
  spec.description   = %q{Medullan analytics, not for the masses}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor", "~> 0.18.1"
  spec.add_runtime_dependency "uuidtools", "~> 2.1.4"
  spec.add_runtime_dependency "activesupport", "~> 4.2"
  spec.add_runtime_dependency "sinatra", "~> 1.4.4"
  spec.add_runtime_dependency "sinatra-contrib", " ~> 1.4.2"
  spec.add_runtime_dependency 'staccato'
  spec.add_runtime_dependency "addressable"
  spec.add_runtime_dependency "newrelic_rpm"
  spec.add_runtime_dependency "jdbc-postgres", "~> 9.3.1102"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "httparty"
  spec.add_runtime_dependency "redis", "~> 3.0.1"
  spec.add_runtime_dependency "hiredis", "~> 0.4.5"
  spec.add_runtime_dependency "connection_pool", "~> 2.0.0"
  spec.add_runtime_dependency "logging", "~> 1.8.2"
  spec.add_runtime_dependency "mail", "~> 2.6.3"
  spec.add_runtime_dependency "browser", "~> 1.1.0"
  spec.add_runtime_dependency "logstash-logger", "~> 0.22.1"
  
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdebug"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "rack-test", "~> 0.6.2"
  spec.add_development_dependency "rr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "ruby-jmeter"
  spec.add_development_dependency "descriptive-statistics"
end

