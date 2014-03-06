# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-azure/version'

Gem::Specification.new do |s|
  s.name          = "vagrant-azure"
  s.version       = VagrantPlugins::WinAzure::VERSION
  s.authors       = ["DeeJay"]
  s.email         = ["dheeraj@nagwani.in"]
  s.description   = "Enable Vagrant to manage machines in Azure"
  s.summary       = "Enable Vagrant to manage machines in Azure"
  s.homepage      = ""
  s.license       = "MIT"

  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-reporters"
  s.add_development_dependency "mocha"
  s.add_development_dependency "azure"
end
