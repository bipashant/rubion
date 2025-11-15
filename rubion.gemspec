# frozen_string_literal: true

require_relative 'lib/rubion/version'

Gem::Specification.new do |spec|
  spec.name = 'rubion'
  spec.version = Rubion::VERSION
  spec.authors = ['bipashant']
  spec.email = ['bs_chapagain@hotmail.com']

  spec.summary = 'Security and version scanner for Ruby and JavaScript projects'
  spec.description = 'Rubion scans your project for Ruby gem vulnerabilities, outdated gems, NPM package vulnerabilities, and outdated packages. It provides a clean, organized report with actionable insights.'
  spec.homepage = 'https://github.com/bipashant/rubion'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/bipashant/rubion'
  spec.metadata['changelog_uri'] = 'https://github.com/bipashant/rubion/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/bipashant/rubion/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('{bin,lib}/**/*') + %w[README.md LICENSE Gemfile rubion.gemspec]
  spec.bindir = 'bin'
  spec.executables = ['rubion']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'terminal-table', '~> 3.0'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.21'
end
