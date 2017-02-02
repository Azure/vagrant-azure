# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

$stdout.sync = true
$stderr.sync = true

Dir.chdir(File.expand_path('../', __FILE__))

Bundler::GemHelper.install_tasks

# Install the `spec` task so that we can run tests.
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--order defined'
end
# Default task is to run the unit tests
task :default => :spec
