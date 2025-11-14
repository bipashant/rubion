# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.6] - 2025-01-14

### Fixed
- Fixed ArgumentError when using `--exclude-dependencies` flag
- Reporter initialize method now properly accepts `exclude_dependencies` parameter

## [0.3.5] - 2025-01-14

### Added
- `--exclude-dependencies` flag to show only direct dependencies (from Gemfile/package.json)
- Bold text highlighting for direct dependencies (replaces ✅ prefix)
- Filter functionality to exclude transitive dependencies from results

### Changed
- Direct dependencies now displayed in bold text instead of ✅ prefix
- Improved visual distinction between direct and transitive dependencies

## [0.3.4] - 2025-01-14

### Added
- Highlight direct dependencies with ✅ prefix in version tables
- Automatic detection of direct gems from Gemfile
- Automatic detection of direct packages from package.json (dependencies, devDependencies, peerDependencies, optionalDependencies)
- Direct dependencies are now visually distinguished from transitive dependencies

### Changed
- Package manager prompt now accepts 'y' for yarn and 'n' for npm (still supports full words)
- Improved code style and formatting

## [0.3.3] - 2025-01-14

### Changed
- Default sort is now "Behind By(Time)" in descending order (most outdated items first)
- Sorting now defaults to descending order for all columns
- Added `--asc` or `--ascending` flag to sort in ascending order when needed

## [0.3.2] - 2025-01-14

### Added
- Sorting functionality for version tables with `--sort-by` or `-s` option
- Support for sorting by: Name, Current, Date, Latest, Behind By(Time), Behind By(Versions)
- Smart parsing for different column types (semantic versions, dates, time differences, numeric counts)
- Case-insensitive column name matching with support for variations

### Changed
- Version tables now support custom sorting based on user preference
- Improved table display with sorted results

## [0.3.1] - 2025-01-14

### Added
- Support for Yarn package manager in addition to npm
- Automatic detection of available package managers (npm and/or yarn)
- Interactive prompt to choose between npm and yarn when both are available
- Updated documentation to reflect yarn support

### Changed
- Package scanning now works with both npm and yarn
- Improved package manager detection using `which` command
- Updated help text and README to mention yarn support

## [0.3.0] - 2025-01-14

### Added
- Real API integration for fetching release dates from RubyGems.org and NPM registry
- "Behind By" column showing time difference (days/months/years) between current and latest versions
- "Versions" column showing count of versions between current and latest
- Progress indicators with counts (e.g., "Checking Ruby gems... 10/54")
- CLI flags: `--gems-only` / `-g` and `--packages-only` / `-p` for selective scanning
- Incremental output: gem results displayed immediately, then packages scanned
- Parallel processing: 10 concurrent threads for API calls (2x faster)
- Severity icons: 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low, ⚪ Unknown
- Single API call per gem/package to fetch all version data (dates + version list)
- Support for "Unknown" criticality from bundle-audit (no longer mapped to Medium)

### Changed
- **Performance**: Reduced scan time from ~8.8s to ~4.1s for gems-only scans
- API calls now fetch all version information in one request instead of multiple calls
- Date format: M/D/YYYY (e.g., "3/5/2024")
- Improved error handling for API calls with timeouts and SSL verification bypass
- Updated output format to include date columns and version analysis

### Fixed
- Fixed "Behind By" calculation to correctly parse dates in M/D/YYYY format
- Fixed CLI flag parsing for `--gems-only` and `--packages-only`
- Improved handling of bundle-audit output when vulnerabilities are found (exit code 1)
- Corrected severity mapping: "Unknown" criticality now shows as "⚪ Unknown" instead of "Medium"

## [0.2.0] - 2025-01-14

### Changed
- **BREAKING**: Complete UI overhaul to match simplified output format
- Removed fancy headers and emoji-heavy formatting
- Changed table structure to be more professional and clean
- Updated vulnerability tables to show: Level, Name, Version, Vulnerability
- Updated version tables to show: Name, Current, Date, Latest, Date
- Removed "Behind By" column in favor of date columns
- Simplified section headers (removed emojis and decorations)
- Removed detailed summary section at the end
- Updated dummy data to match new examples

### Added
- Date columns for current and latest versions (currently showing 'N/A', ready for future API integration)
- Cleaner, more professional table output

### Removed
- Fancy header with ASCII art
- Color-coded severity emojis (🔴 🟠 🟡 🟢)
- "Behind By" version difference calculation
- Advisory/CVE column from vulnerability table
- Detailed summary statistics
- Border styling (border_x, border_i)
- Table titles

## [0.1.2] - 2025-01-14

### Fixed
- Fixed "Table width exceeds wanted width" runtime error
- Removed fixed width constraints from all tables to allow flexible terminal sizes
- Added proper truncation for long package/gem names to prevent overflow
- Tables now automatically adapt to terminal width

### Changed
- Gem names truncated to 25-30 characters in tables
- Package names truncated to 30-40 characters in tables
- Removed hard-coded width limits (120, 100) from terminal-table style
- Improved table readability for long package names

## [0.1.1] - 2025-01-14

### Fixed
- Fixed npm audit parsing error when vulnerability data contains unexpected types
- Added better type checking for npm audit and npm outdated data
- Added rescue blocks to handle parsing errors gracefully
- Fixed `undefined method 'dig' for String` error when parsing npm vulnerabilities
- Improved error messages for npm scanning failures

### Changed
- Enhanced `parse_npm_audit_output` to handle various data structures
- Enhanced `parse_npm_outdated_output` with type checking
- Better handling of the `via` field in npm audit data (can be String or Array)

## [0.1.0] - 2025-01-13

### Added
- Initial release of Rubion
- Ruby gem vulnerability scanning using bundler-audit
- Ruby gem version checking using bundle outdated
- NPM package vulnerability scanning using npm audit
- NPM package version checking using npm outdated
- Beautiful terminal table output with color-coded severity levels
- CLI interface with `rubion scan` command
- Dummy data fallback for demonstration when tools are not available
- Comprehensive README with usage examples
- MIT License
- Test structure with basic tests
- RuboCop configuration
- Rake tasks for common operations

### Features
- 📛 Gem Vulnerabilities detection
- 📦 Gem Versions (outdated) detection
- 📛 NPM Package Vulnerabilities detection
- 📦 NPM Package Versions (outdated) detection
- 📊 Summary report with actionable insights
- 🎨 Color-coded severity indicators (Critical, High, Medium, Low)
- 🚀 Simple CLI with help command

[Unreleased]: https://github.com/yourusername/rubion/compare/v0.3.6...HEAD
[0.3.6]: https://github.com/yourusername/rubion/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/yourusername/rubion/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/yourusername/rubion/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/yourusername/rubion/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/yourusername/rubion/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/yourusername/rubion/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/yourusername/rubion/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yourusername/rubion/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/yourusername/rubion/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/yourusername/rubion/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/yourusername/rubion/releases/tag/v0.1.0
