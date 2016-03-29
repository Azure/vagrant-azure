# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

source 'https://rubygems.org'

gemspec

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: 'git://github.com/mitchellh/vagrant.git', tag: 'v1.7.4'
  gem 'dotenv'
end

group :plugins do
  gem 'vagrant-azure', path: '.'
end
