# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'vagrant-azure'

if ENV['COVERAGE'] || ENV['CI'] || ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  if ENV['TRAVIS']
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
        SimpleCov::Formatter::HTMLFormatter,
        Coveralls::SimpleCov::Formatter
    ]
  else
    SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  end

  SimpleCov.start do
    project_name 'vagrant-azure'
    add_filter '/build-tests/'
    add_filter '/coverage/'
    add_filter '/locales/'
    add_filter '/templates/'
    add_filter '/doc/'
    add_filter '/example_box/'
    add_filter '/pkg/'
    add_filter '/spec/'
    add_filter '/tasks/'
    add_filter '/yard-template/'
    add_filter '/yardoc/'
  end
end

# import all the support files
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.order = 'random'
end