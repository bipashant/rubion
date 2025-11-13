# 🔒 Rubion

**Rubion** is a security and version scanner for Ruby and JavaScript projects. It helps you identify vulnerabilities and outdated dependencies in your Ruby gems and NPM packages.

## Features

- 📛 **Gem Vulnerabilities**: Scans for known security vulnerabilities in Ruby gems
- 📦 **Gem Versions**: Identifies outdated Ruby gems
- 📛 **Package Vulnerabilities**: Scans for known security vulnerabilities in NPM packages
- 📦 **Package Versions**: Identifies outdated NPM packages
- 📊 **Beautiful Reports**: Organized table output with color-coded severity levels
- 🚀 **Easy to Use**: Simple CLI interface with a single command

## Installation

### Install from RubyGems (when published)

```bash
gem install rubion
```

### Install from source

```bash
git clone https://github.com/yourusername/rubion.git
cd rubion
bundle install
rake install_local
```

## Usage

### Scan your project

Navigate to your project directory and run:

```bash
rubion scan
```

This will scan your project for:
- Ruby gem vulnerabilities (if `Gemfile.lock` exists)
- Outdated Ruby gems
- NPM package vulnerabilities (if `package.json` exists)
- Outdated NPM packages

### View help

```bash
rubion help
```

### Check version

```bash
rubion version
```

## Output Example

```
================================================================================
  🔒 RUBION SECURITY & VERSION SCAN REPORT
================================================================================

📛 GEM VULNERABILITIES

+==============================================================================+
|                       Ruby Gem Vulnerabilities                              |
+------------+----------+-----------+----------------+------------------------+
| Gem        | Version  | Severity  | Advisory       | Title                  |
+------------+----------+-----------+----------------+------------------------+
| rack       | 2.0.8    | 🔴 High   | CVE-2022-44570 | Denial of Service...   |
| nokogiri   | 1.10.4   | 🔴 Critical| CVE-2021-30560| Update bundled libxml2 |
+------------+----------+-----------+----------------+------------------------+

📦 GEM VERSIONS (Outdated)

+====================================================================+
|                     Outdated Ruby Gems                             |
+----------------+------------------+----------------+---------------+
| Gem            | Current Version  | Latest Version | Behind By     |
+----------------+------------------+----------------+---------------+
| puma           | 4.3.8            | 6.4.0          | 2 major       |
| devise         | 4.7.3            | 4.9.3          | 2 minor       |
+----------------+------------------+----------------+---------------+

================================================================================
  📊 SUMMARY
================================================================================
  Total Vulnerabilities: 🔴 5
  Total Outdated: 10
================================================================================

⚠️  ACTION REQUIRED: Please update vulnerable dependencies!
```

## Requirements

- Ruby 2.6 or higher
- Bundler (for Ruby gem scanning)
- NPM (optional, for NPM package scanning)
- `bundler-audit` (optional, for enhanced gem vulnerability detection)

### Installing bundler-audit (recommended)

```bash
gem install bundler-audit
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

### Running tests

```bash
rake spec
```

### Running RuboCop

```bash
rake rubocop
```

### Building the gem

```bash
gem build rubion.gemspec
```

### Installing locally

```bash
rake install_local
```

## How It Works

Rubion uses a modular architecture:

1. **Scanner** (`lib/rubion/scanner.rb`): Executes various commands to scan for vulnerabilities and outdated versions
   - `bundle-audit` for gem vulnerabilities
   - `bundle outdated` for gem versions
   - `npm audit` for package vulnerabilities
   - `npm outdated` for package versions

2. **Reporter** (`lib/rubion/reporter.rb`): Formats scan results into beautiful terminal tables using `terminal-table`

3. **CLI** (`lib/rubion.rb`): Provides the command-line interface

## Extending Rubion

Rubion is designed to be easily extensible. To add new scanners:

1. Add a new method in `lib/rubion/scanner.rb`
2. Add a corresponding report method in `lib/rubion/reporter.rb`
3. Update the scan flow in `Scanner#scan`

Example:

```ruby
# In scanner.rb
def scan_python_packages
  # Your scanning logic here
  @result.python_vulnerabilities = check_pip_vulnerabilities
end

# In reporter.rb
def print_python_vulnerabilities
  # Your reporting logic here
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/rubion.

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rubion project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the code of conduct.

## Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the documentation
- Contact the maintainers

## Roadmap

Future features planned:
- [ ] Support for Python (pip) packages
- [ ] Support for PHP (composer) packages
- [ ] Support for Go modules
- [ ] JSON/CSV output formats
- [ ] CI/CD integration
- [ ] Configurable severity thresholds
- [ ] Auto-fix suggestions
- [ ] Historical tracking of vulnerabilities

## Acknowledgments

- Built with [terminal-table](https://github.com/tj/terminal-table)
- Inspired by tools like `bundle-audit` and `npm audit`

