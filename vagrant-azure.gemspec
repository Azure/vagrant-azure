# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-azure/version'

Gem::Specification.new do |s|
  s.name          = 'vagrant-azure'
  s.version       = VagrantPlugins::WinAzure::VERSION
  s.authors       = ['MSOpenTech']
  s.description   = 'Enable Vagrant to manage machines in Azure'
  s.summary       = 'Enable Vagrant to manage machines in Azure'
  s.homepage      = 'https://github.com/MSOpenTech/vagrant-azure'
  s.license       = 'Apache 2.0'
  s.require_paths = ['lib']
  s.files         = `git ls-files`.split("\n")
  s.bindir        = 'bin'
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_runtime_dependency 'azure', '0.7.0.pre2'
  s.add_runtime_dependency 'httpclient', '2.4.0'

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'mocha'
end
