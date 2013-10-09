# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iox/spielplan/version'

Gem::Specification.new do |spec|
  spec.name          = "iox-spielplan"
  spec.version       = Iox::Spielplan::VERSION
  spec.authors       = ["quaqua"]
  spec.email         = ["quaqua@tastenwerk.com"]
  spec.description   = %q{spielplan module}
  spec.summary       = %q{spielplan module for iox}
  spec.homepage      = ""
  spec.license       = "commercial"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

end
