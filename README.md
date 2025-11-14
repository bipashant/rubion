#  Rubion

**Rubion** is a security and version scanner for Ruby and JavaScript projects. It helps you identify vulnerabilities and outdated dependencies in your Ruby gems and NPM packages.

<img width="1237" height="671" alt="Screenshot 2025-11-14 at 10 48 12 am" src="https://github.com/user-attachments/assets/a3d93452-c442-416a-9697-de59746e16ad" />

## Features

- 📛 **Gem Vulnerabilities**: Scans for known security vulnerabilities in Ruby gems using `bundle-audit`
- 📦 **Gem Versions**: Identifies outdated Ruby gems with release dates and version counts
- 📛 **Package Vulnerabilities**: Scans for known security vulnerabilities in NPM packages using `npm audit`
- 📦 **Package Versions**: Identifies outdated NPM packages with release dates and version counts
- 📊 **Beautiful Reports**: Organized table output with severity icons (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low, ⚪ Unknown)
- 🚀 **Fast & Efficient**: Parallel API processing (10 concurrent threads) for quick results
- ⚡ **Incremental Output**: Shows gem results immediately, then scans packages
- 📅 **Release Dates**: Fetches actual release dates from RubyGems.org and NPM registry
- 🔢 **Version Analysis**: Shows how many versions behind and time difference

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
- Outdated Ruby gems with release dates
- NPM package vulnerabilities (if `package.json` exists)
- Outdated NPM packages with release dates

### Scan options

```bash
# Scan only Ruby gems (skip NPM packages)
rubion scan --gems-only
# or
rubion scan -g

# Scan only NPM packages (skip Ruby gems)
rubion scan --packages-only
# or
rubion scan -p

# Scan both (default)
rubion scan
```

### View help

```bash
rubion help
```

### Check version

```bash
rubion version
# or
rubion -v
```

## Output Example

```
🔍 Scanning project at: /path/to/project

📦 Checking Ruby gems... 139/139 ✓

Gem Vulnerabilities:

+----------+--------+---------+------------------------------------------+
| Level    | Name   | Version | Vulnerability                            |
+----------+--------+---------+------------------------------------------+
| 🔴 Critical | rexml | 3.4.1   | REXML has DoS condition when parsing... |
| 🟠 High  | rack   | 2.0.8   | Denial of Service vulnerability         |
+----------+--------+---------+------------------------------------------+

Gem Versions:

+----------+---------+-----------+---------+-----------+-----------+----------+
| Name     | Current | Date      | Latest  | Date      | Behind By | Versions |
+----------+---------+-----------+---------+-----------+-----------+----------+
| sidekiq  | 7.30    | 3/5/2024  | 8.1     | 11/11/2025| 1 year    | 15       |
| fastimage| 2.2.7   | 2/2/2025  | 2.3.2   | 9/9/2025  | 7 months  | 3        |
+----------+---------+-----------+---------+-----------+-----------+----------+

📦 Checking NPM packages... 45/45 ✓

Package Vulnerabilities:

+----------+--------+---------+------------------------------------------+
| Level    | Name   | Version | Vulnerability                            |
+----------+--------+---------+------------------------------------------+
| 🟠 High  | moment | 1.2.3   | Wrong timezone date calculation         |
+----------+--------+---------+------------------------------------------+

Package Versions:

+----------+---------+-----------+---------+-----------+-----------+----------+
| Name     | Current | Date      | Latest  | Date      | Behind By | Versions |
+----------+---------+-----------+---------+-----------+-----------+----------+
| jquery   | 3.7.1   | 4/5/2024  | 3.9.1   | 10/11/2025| 1 year    | 8        |
+----------+---------+-----------+---------+-----------+-----------+----------+
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

**Note:** Without `bundler-audit`, gem vulnerability scanning will be skipped.

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
   - `bundle-audit check` for gem vulnerabilities
   - `bundle outdated --parseable` for gem versions
   - `npm audit --json` for package vulnerabilities
   - `npm outdated --json` for package versions
   - Fetches release dates and version data from RubyGems.org and NPM registry APIs
   - Uses parallel processing (10 concurrent threads) for fast API calls

2. **Reporter** (`lib/rubion/reporter.rb`): Formats scan results into beautiful terminal tables using `terminal-table`
   - Adds severity icons (🔴 🟠 🟡 🟢 ⚪)
   - Formats dates, time differences, and version counts
   - Supports incremental output (gems first, then packages)

3. **CLI** (`lib/rubion.rb`): Provides the command-line interface
   - Parses command-line options (`--gems-only`, `--packages-only`)
   - Coordinates scanning and reporting

For detailed information about data collection and mapping, see [HOW_IT_WORKS.md](HOW_IT_WORKS.md).

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

## Performance

Rubion is optimized for speed:

- **Parallel API Processing**: Uses 10 concurrent threads to fetch version data from RubyGems.org and NPM registry
- **Single API Call Per Package**: Fetches all necessary data (dates, version list) in one request
- **Incremental Output**: Shows gem results immediately, then scans packages (better UX)
- **Progress Indicators**: Shows real-time progress like "Checking Ruby gems... 10/54"

Typical scan times:
- Gems only: ~4-5 seconds (for ~140 gems)
- Packages only: ~3-4 seconds (for ~50 packages)
- Both: ~7-9 seconds total

## Roadmap

Future features planned:
- [ ] Sorting options (by severity, name, date, etc.)
- [ ] Filtering options (by severity, outdated threshold, etc.)
- [ ] Export formats (JSON, CSV, HTML)
- [ ] Summary statistics
- [ ] Update command suggestions
- [ ] Support for Python (pip) packages
- [ ] Support for PHP (composer) packages
- [ ] Support for Go modules
- [ ] CI/CD integration flags
- [ ] Configurable severity thresholds
- [ ] Auto-fix suggestions
- [ ] Historical tracking of vulnerabilities

## Acknowledgments

- Built with [terminal-table](https://github.com/tj/terminal-table)
- Inspired by tools like `bundle-audit` and `npm audit`

