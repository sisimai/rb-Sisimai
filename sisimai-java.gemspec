# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sisimai/version'

Gem::Specification.new do |spec|
  spec.name    = 'sisimai'
  spec.version = Sisimai::VERSION
  spec.authors = ['azumakuniyuki']
  spec.email   = ['azumakuniyuki+rubygems.org@gmail.com']

  spec.summary       = 'Mail Analyzing Interface'
  spec.description   = 'Sisimai is a Ruby library for analyzing RFC5322 bounce emails and generating structured data from parsed results.'
  spec.homepage      = 'https://libsisimai.org/'
  spec.license       = 'BSD-2-Clause'
  spec.platform      = "java"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_development_dependency 'bundler',  '>= 1.8'
  spec.add_development_dependency 'rake',     '>= 10.0'
  spec.add_development_dependency 'minitest', '>= 5.0'
  spec.add_runtime_dependency     'jrjackson','~> 0.3', '>= 0.3.8'
end
