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

### 2. Scan Options

```bash
# Scan only Ruby gems
rubion scan --gems-only
# or
rubion scan -g

# Scan only NPM packages
rubion scan --packages-only
# or
rubion scan -p

# Scan both (default)
rubion scan
```

### 3. View Help

```bash
rubion help
```

### 4. Check Version

```bash
rubion version
# or
rubion -v
```

## Example Output

When you run `rubion scan`, you'll see a comprehensive report like this:

```
🔍 Scanning project at: /your/project

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
- Learn how it works: [HOW_IT_WORKS.md](HOW_IT_WORKS.md)
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

