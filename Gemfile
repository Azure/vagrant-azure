# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

source "https://rubygems.org"

gemspec

group :development, :test do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem "vagrant", git: "https://github.com/mitchellh/vagrant.git", tag: "v1.9.2"
end

group :plugins do
  gem "vagrant-azure", path: "."
end