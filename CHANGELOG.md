# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/yourusername/rubion/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/yourusername/rubion/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/yourusername/rubion/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/yourusername/rubion/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/yourusername/rubion/releases/tag/v0.1.0
