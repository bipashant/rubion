# 🚀 Rubion Quick Start Guide

Get up and running with Rubion in minutes!

## Installation

### Method 1: Install from source (recommended for development)

```bash
# Clone the repository
git clone https://github.com/yourusername/rubion.git
cd rubion

# Install dependencies
bundle install

# Install the gem locally
rake install_local
```

### Method 2: Install from RubyGems (when published)

```bash
gem install rubion
```

## Usage

### 1. Basic Scan

Navigate to any Ruby or JavaScript project and run:

```bash
cd /path/to/your/project
rubion scan
```

### 2. View Help

```bash
rubion help
```

### 3. Check Version

```bash
rubion version
```

## Example Output

When you run `rubion scan`, you'll see a comprehensive report like this:

```
🔍 Scanning project at: /your/project

📦 Checking Ruby gems...
📦 Checking NPM packages...

================================================================================
  🔒 RUBION SECURITY & VERSION SCAN REPORT
================================================================================

📛 GEM VULNERABILITIES

+------------------------------------------------------------------------+
|                       Ruby Gem Vulnerabilities                         |
+----------+--------+----------+--------------+-------------------------+
| Gem      | Version| Severity | Advisory     | Title                   |
+----------+--------+----------+--------------+-------------------------+
| rack     | 2.0.8  | 🔴 High  | CVE-2022-... | Denial of Service...    |
+----------+--------+----------+--------------+-------------------------+

📊 SUMMARY: 3 vulnerabilities found, 5 packages outdated
```

## Testing in Development

### Test without installing

```bash
# From the rubion directory
./bin/rubion scan

# Or use ruby directly
ruby -Ilib bin/rubion scan
```

### Run tests

```bash
rake spec
```

### Run RuboCop

```bash
rake rubocop
```

## Recommended Tools

For the best experience, install these optional dependencies:

```bash
# For gem vulnerability scanning
gem install bundler-audit

# Update bundler-audit database
bundle-audit update
```

## Common Use Cases

### CI/CD Integration

Add to your `.github/workflows/security.yml`:

```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0
      - run: gem install rubion
      - run: rubion scan
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
rubion scan
```

### Scheduled Scans

Add to crontab:

```bash
# Run daily at 9 AM
0 9 * * * cd /path/to/project && rubion scan | mail -s "Security Scan Report" your@email.com
```

## Troubleshooting

### "Command not found: rubion"

Make sure the gem is installed and in your PATH:

```bash
gem list rubion
which rubion
```

### "Could not run bundle-audit"

Install bundler-audit for better gem vulnerability detection:

```bash
gem install bundler-audit
```

### No vulnerabilities found but I know there are some

1. Update bundler-audit database: `bundle-audit update`
2. Make sure you're in the project root directory
3. Check that `Gemfile.lock` or `package.json` exists

## Next Steps

- Read the full [README.md](README.md)
- Check out the [CHANGELOG.md](CHANGELOG.md)
- Visit the [GitHub repository](https://github.com/yourusername/rubion)
- Report issues or contribute!

## Support

Need help? 
- Open an issue on GitHub
- Check the documentation
- Email: your.email@example.com

---

**Happy scanning! 🔒**

