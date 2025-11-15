# frozen_string_literal: true

require_relative 'lib/rubion/version'

Gem::Specification.new do |spec|
  spec.name = 'rubion'
  spec.version = Rubion::VERSION
  spec.authors = ['bipashant']
  spec.email = ['bs_chapagain@hotmail.com']

  spec.summary = 'Security and version scanner for Ruby and JavaScript projects'
  spec.description = <<~DESC
    Rubion is a comprehensive security and version scanner for Ruby and JavaScript projects.
    It helps you identify vulnerabilities and outdated dependencies in your Ruby gems and NPM/JavaScript packages.

    ## Features

    - 📛 Gem Vulnerabilities: Scans for known security vulnerabilities in Ruby gems using bundle-audit
    - 📦 Gem Versions: Identifies outdated Ruby gems with release dates and version counts
    - 📛 Package Vulnerabilities: Scans for known security vulnerabilities in NPM/JavaScript packages
    - 📦 Package Versions: Identifies outdated NPM/JavaScript packages with release dates
    - 🎯 Direct Dependencies: Highlights direct dependencies (from Gemfile/package.json) in bold text
    - 🔍 Filtering: Option to show only direct dependencies with --exclude-dependencies flag
    - 📊 Sorting: Sort results by any column (Name, Current, Date, Latest, Behind By(Time), Behind By(Versions))
    - 🚀 Fast & Efficient: Parallel API processing (10 concurrent threads) for quick results
    - 📦 Multi-Package Manager: Supports both npm and yarn with automatic detection

    ## Installation

    ```bash
    gem install rubion
    ```

    Or add to your Gemfile:

    ```ruby
    gem 'rubion', '~> 0.3.10'
    ```

    ## Usage

    ### Basic Scan

    ```bash
    rubion scan
    ```

    ### Scan Options

    ```bash
    # Scan only Ruby gems
    rubion scan --gems-only
    # or
    rubion scan -g

    # Scan only NPM packages
    rubion scan --packages-only
    # or
    rubion scan -p

    # Sort by column
    rubion scan --sort-by Name
    rubion scan --sort-by "Behind By(Time)" --desc

    # Show only direct dependencies
    rubion scan --exclude-dependencies
    ```

    ### Example Output

    Complete Scan Output:

    ```
    🔍 Scanning project at: /path/to/project

    📦 Checking Ruby gems... 139/139 ✓

    Gem Vulnerabilities:

    +----------+--------+---------+------------------------------------------+
    | Level    | Name   | Version | Vulnerability                            |
    +----------+--------+---------+------------------------------------------+
    | 🔴 Critical | rexml | 3.4.1   | REXML has DoS condition when parsing... |
    | 🟠 High  | rack   | 2.0.8   | Denial of Service vulnerability         |
    | 🟡 Medium | nokogiri | 1.13.8 | XML parsing vulnerability              |
    | 🟢 Low   | json   | 2.6.1   | JSON parsing issue                      |
    +----------+--------+---------+------------------------------------------+

    Gem Versions:

    +------------------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    | Name             | Current | Current version released on | Latest  | Latest version released on | Behind By(Time) ↓ | Behind By(Versions) |
    +------------------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    | sidekiq          | 7.30    | 3/5/2024                 | 8.1     | 11/11/2025               | 1 year           | 15                |
    | rails             | 7.0.0   | 12/15/2022               | 7.1.0   | 10/4/2024                | 1 year 10 months | 8                 |
    | fastimage         | 2.2.7   | 2/2/2025                  | 2.3.2   | 9/9/2025                 | 7 months         | 3                 |
    | nokogiri          | 1.13.8 | 5/10/2023                 | 1.15.0  | 8/20/2024                | 1 year 3 months  | 12                |
    | redis             | 4.8.0  | 1/15/2023                 | 5.0.0   | 11/1/2024                | 1 year 9 months  | 20                |
    | pg                | 1.4.0  | 3/20/2023                 | 1.5.0   | 9/15/2024                | 1 year 5 months  | 6                 |
    +------------------+---------+--------------------------+---------+--------------------------+------------------+-------------------+

    📦 Checking NPM packages... 45/45 ✓

    Package Vulnerabilities:

    +----------+--------+---------+------------------------------------------+
    | Level    | Name   | Version | Vulnerability                            |
    +----------+--------+---------+------------------------------------------+
    | 🔴 Critical | lodash | 4.17.20 | Prototype pollution vulnerability    |
    | 🟠 High  | moment | 2.29.1  | Wrong timezone date calculation         |
    | 🟡 Medium | axios  | 0.21.1  | Server-Side Request Forgery (SSRF)      |
    | 🟢 Low   | debug  | 4.3.1   | Regular Expression Denial of Service   |
    +----------+--------+---------+------------------------------------------+

    Package Versions:

    +------------------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    | Name             | Current | Current version released on | Latest  | Latest version released on | Behind By(Time) ↓ | Behind By(Versions) |
    +------------------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    | react             | 17.0.2 | 3/3/2021                  | 18.2.0  | 6/14/2023                | 2 years 3 months | 45                |
    | vue               | 3.2.0  | 8/5/2021                  | 3.3.0   | 5/18/2023                | 1 year 9 months  | 8                 |
    | jquery            | 3.7.1  | 4/5/2024                  | 3.9.1   | 10/11/2025               | 1 year           | 8                 |
    | express           | 4.18.0 | 4/25/2022                 | 4.18.2  | 8/15/2023                | 1 year 3 months  | 2                 |
    | webpack           | 5.70.0 | 3/1/2022                  | 5.88.0  | 6/1/2023                 | 1 year 3 months  | 18                |
    | typescript        | 4.7.0  | 5/24/2022                 | 5.1.0   | 5/25/2023                | 1 year           | 12                |
    +------------------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    ```

    Direct Dependencies Only (with --exclude-dependencies):

    ```
    Gem Versions:

    +----------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    | Name     | Current | Current version released on | Latest  | Latest version released on | Behind By(Time) ↓ | Behind By(Versions) |
    +----------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    | **rails**| 7.0.0   | 12/15/2022               | 7.1.0   | 10/4/2024                | 1 year 10 months | 8                 |
    | **sidekiq**| 7.30  | 3/5/2024                 | 8.1     | 11/11/2025               | 1 year           | 15                |
    | **pg**   | 1.4.0  | 3/20/2023                 | 1.5.0   | 9/15/2024                | 1 year 5 months  | 6                 |
    +----------+---------+--------------------------+---------+--------------------------+------------------+-------------------+
    ```

    Note: Direct dependencies (from Gemfile or package.json) are displayed in bold text in the version tables.

    ## Requirements

    - Ruby 2.6 or higher
    - Bundler (for Ruby gem scanning)
    - NPM or Yarn (optional, for JavaScript package scanning)
    - bundler-audit (optional, install with: gem install bundler-audit)

    ## Documentation

    For more information, visit: https://github.com/bipashant/rubion
  DESC
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
