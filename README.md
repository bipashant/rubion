# Rubion

**Rubion** is a security and version scanner for Ruby and JavaScript projects. It helps you identify vulnerabilities and outdated dependencies in your Ruby gems and NPM/JavaScript packages.

<img width="1237" height="671" alt="Screenshot 2025-11-14 at 10 48 12 am" src="https://github.com/user-attachments/assets/a3d93452-c442-416a-9697-de59746e16ad" />

## Features

- 📛 **Gem Vulnerabilities**: Scans for known security vulnerabilities in Ruby gems using `bundle-audit`
- 📦 **Gem Versions**: Identifies outdated Ruby gems with release dates and version counts
- 📛 **Package Vulnerabilities**: Scans for known security vulnerabilities in NPM/JavaScript packages using `npm audit` or `yarn audit`
- 📦 **Package Versions**: Identifies outdated NPM/JavaScript packages with release dates and version counts
- 🎯 **Direct Dependencies**: Highlights direct dependencies (from `Gemfile`/`package.json`) in bold text
- 🔍 **Filtering**: Option to show only direct dependencies with `--exclude-dependencies` flag
- 📊 **Sorting**: Sort results by any column (Name, Current, Date, Latest, Behind By(Time), Behind By(Versions))
- 📊 **Beautiful Reports**: Organized table output with severity icons (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low, ⚪ Unknown)
- 🚀 **Fast & Efficient**: Parallel API processing (10 concurrent threads) for quick results
- ⚡ **Incremental Output**: Shows gem results immediately, then scans packages
- 📅 **Release Dates**: Fetches actual release dates from RubyGems.org and NPM registry
- 🔢 **Version Analysis**: Shows how many versions behind and time difference
- 📦 **Multi-Package Manager**: Supports both npm and yarn with automatic detection

## Installation

### Install from RubyGems

```bash
gem install rubion
```

### Install from source

```bash
git clone https://github.com/bipashant/rubion.git
cd rubion
bundle install
rake install_local
```

## Usage

### Basic Scan

Navigate to your project directory and run:

```bash
rubion scan
```

This will scan your project for:
- Ruby gem vulnerabilities (if `Gemfile.lock` exists)
- Outdated Ruby gems with release dates
- NPM/JavaScript package vulnerabilities (if `package.json` exists)
- Outdated NPM/JavaScript packages with release dates

### Scan Options

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

### Sorting Options

```bash
# Sort by column name (default: "Behind By(Time)" in descending order)
rubion scan --sort-by Name
rubion scan --sort-by Current
rubion scan --sort-by "Current version released on"
rubion scan --sort-by Latest
rubion scan --sort-by "Latest version released on"
rubion scan --sort-by "Behind By(Time)"
rubion scan --sort-by "Behind By(Versions)"

# Short form
rubion scan -s Name

# Sort in ascending order
rubion scan --sort-by Name --asc
rubion scan --sort-by Name --ascending

# Sort in descending order (default)
rubion scan --sort-by Name --desc
rubion scan --sort-by Name --descending
```

**Available columns for sorting:**
- `Name` - Package/gem name
- `Current` - Current version
- `Current version released on` or `Date` - Release date of current version
- `Latest` - Latest version
- `Latest version released on` or `Date` - Release date of latest version
- `Behind By(Time)` - Time difference (default sort, descending)
- `Behind By(Versions)` - Number of versions behind

### Filtering Options

```bash
# Show only direct dependencies (from Gemfile/package.json)
rubion scan --exclude-dependencies
```

Direct dependencies are automatically highlighted in **bold text** in the output.

### View Help

```bash
rubion help
# or
rubion -h
```

### Check Version

```bash
rubion version
# or
rubion -v
```

## Output Example

### Complete Scan Output

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

### Direct Dependencies Only (with --exclude-dependencies)

When using `rubion scan --exclude-dependencies`, only direct dependencies are shown:

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

**Note:** Direct dependencies (from `Gemfile` or `package.json`) are displayed in **bold text** in the version tables. In the example above, `rails`, `sidekiq`, and `pg` are direct dependencies from the `Gemfile`.

## Requirements

- Ruby 2.6 or higher
- Bundler (for Ruby gem scanning)
- NPM or Yarn (optional, for JavaScript package scanning)
- `bundler-audit` (optional, for enhanced gem vulnerability detection)

**Note:** If both npm and yarn are available, Rubion will prompt you to choose which one to use. You can respond with 'y' for yarn or 'n' for npm.

### Installing bundler-audit (recommended)

```bash
gem install bundler-audit
```

**Note:** Without `bundler-audit`, gem vulnerability scanning will be skipped.

## How It Works

Rubion uses a modular architecture:

1. **Scanner** (`lib/rubion/scanner.rb`): Executes various commands to scan for vulnerabilities and outdated versions
   - `bundle-audit check` for gem vulnerabilities
   - `bundle outdated --parseable` for gem versions
   - `npm audit --json` or `yarn audit --json` for package vulnerabilities (auto-detects which is available)
   - `npm outdated --json` or `yarn outdated` for package versions (auto-detects which is available)
   - Fetches release dates and version data from RubyGems.org and NPM registry APIs
   - Uses parallel processing (10 concurrent threads) for fast API calls
   - Prompts user to choose between npm and yarn if both are available
   - Parses `Gemfile` and `package.json` to identify direct dependencies

2. **Reporter** (`lib/rubion/reporter.rb`): Formats scan results into beautiful terminal tables using `terminal-table`
   - Adds severity icons (🔴 🟠 🟡 🟢 ⚪)
   - Formats dates, time differences, and version counts
   - Supports incremental output (gems first, then packages)
   - Highlights direct dependencies in bold text
   - Supports sorting by any column with visual indicators (↑/↓)
   - Filters results based on `--exclude-dependencies` flag

3. **CLI** (`lib/rubion.rb`): Provides the command-line interface
   - Parses command-line options (`--gems-only`, `--packages-only`, `--sort-by`, `--asc`, `--desc`, `--exclude-dependencies`)
   - Coordinates scanning and reporting

For detailed information about data collection and mapping, see [HOW_IT_WORKS.md](HOW_IT_WORKS.md).

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

Bug reports and pull requests are welcome on GitHub at https://github.com/bipashant/rubion.

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

If you have any questions or need help, please:
- Open an issue on GitHub: https://github.com/bipashant/rubion/issues
- Check the documentation
- Review the [CHANGELOG.md](CHANGELOG.md) for recent changes

## Roadmap

Future features planned:
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
