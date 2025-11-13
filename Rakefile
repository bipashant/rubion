# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run tests"
task default: :spec

desc "Run RuboCop"
task rubocop: :rubocop

desc "Install the gem locally"
task :install_local do
  sh "gem build rubion.gemspec"
  sh "gem install ./rubion-#{Rubion::VERSION}.gem"
end

desc "Uninstall the gem"
task :uninstall do
  sh "gem uninstall rubion"
end

