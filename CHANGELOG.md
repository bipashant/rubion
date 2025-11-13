# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/yourusername/rubion/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/yourusername/rubion/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/yourusername/rubion/releases/tag/v0.1.0
