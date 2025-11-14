# How Rubion Works - Data Collection & Mapping

This document explains how each section of Rubion's output is generated at a surface level.

## Overview

Rubion scans your project by:
1. Running external commands (`bundle-audit`, `bundle outdated`, `npm audit`, `npm outdated`)
2. Parsing their text/JSON output
3. Enriching data with API calls (for dates and version counts)
4. Formatting results into tables

---

## 📛 Gem Vulnerabilities

**Data Source:** `bundle-audit check` command

**How it works:**
1. Runs `bundle-audit check` in your project directory
2. Parses the text output line by line looking for:
   - `Name:` → gem name
   - `Version:` → vulnerable version
   - `CVE:` → CVE identifier
   - `Criticality:` → severity level (Critical, High, Medium, Low, Unknown)
   - `Title:` → vulnerability description
3. Maps each vulnerability to a hash with: `gem`, `version`, `severity`, `title`, `advisory`
4. Displays in table with severity icons (🔴 Critical, 🟠 High, 🟡 Medium, ⚪ Unknown, 🟢 Low)

**Note:** Requires `bundler-audit` gem to be installed. Falls back to empty results if not available.

---

## 📦 Gem Versions

**Data Source:** `bundle outdated --parseable` command + RubyGems API

**How it works:**
1. Runs `bundle outdated --parseable` to get list of outdated gems
2. Parses output format: `gem_name (newest version, installed version)`
3. For each outdated gem, makes **one API call** to RubyGems.org:
   - Fetches all versions and their release dates
   - Extracts dates for current and latest versions
   - Counts versions between current and latest
4. Calculates time difference between release dates
5. Maps to hash with: `gem`, `current`, `current_date`, `latest`, `latest_date`, `time_diff`, `version_count`
6. Displays in table with "Behind By" (time) and "Versions" (count) columns

**Optimization:** Uses parallel processing (10 concurrent threads) to fetch API data faster.

---

## 📛 Package Vulnerabilities

**Data Source:** `npm audit --json` command

**How it works:**
1. Runs `npm audit --json` in your project directory
2. Parses the JSON response structure:
   - `vulnerabilities` object contains all vulnerable packages
   - Each package has: `severity`, `range`/`version`, `via` (array with vulnerability details)
3. Extracts vulnerability title from the `via` array (handles both String and Array formats)
4. Maps each vulnerability to a hash with: `package`, `version`, `severity`, `title`
5. Displays in table with severity icons (same as gems)

**Note:** Requires `npm` to be installed. Falls back to empty results if not available.

---

## 📦 Package Versions

**Data Source:** `npm outdated --json` command + NPM Registry API

**How it works:**
1. Runs `npm outdated --json` to get list of outdated packages
2. Parses JSON structure with package names as keys
3. For each outdated package, makes **one API call** to registry.npmjs.org:
   - Fetches package metadata including `time` object (all version release dates)
   - Extracts dates for current and latest versions
   - Sorts versions by release date and counts versions between current and latest
4. Calculates time difference between release dates
5. Maps to hash with: `package`, `current`, `current_date`, `latest`, `latest_date`, `time_diff`, `version_count`
6. Displays in table with "Behind By" (time) and "Versions" (count) columns

**Optimization:** Uses parallel processing (10 concurrent threads) to fetch API data faster.

---

## Data Flow Summary

```
┌─────────────────────────────────────────────────────────┐
│ 1. Run External Commands                                  │
│    - bundle-audit check                                  │
│    - bundle outdated --parseable                         │
│    - npm audit --json                                    │
│    - npm outdated --json                                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 2. Parse Output                                          │
│    - Text parsing (bundle-audit, bundle outdated)       │
│    - JSON parsing (npm audit, npm outdated)             │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Enrich with API Data (Parallel - 10 threads)         │
│    - RubyGems.org API (for gem dates & version counts)  │
│    - registry.npmjs.org API (for package dates & counts)│
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 4. Calculate Derived Fields                             │
│    - Time difference (days/months/years)                │
│    - Version count between current and latest            │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 5. Format & Display                                      │
│    - Add severity icons                                  │
│    - Format dates (M/D/YYYY)                             │
│    - Create tables with terminal-table gem               │
└─────────────────────────────────────────────────────────┘
```

---

## Key Optimizations

1. **Single API Call Per Gem/Package:** Instead of 3 separate calls (current date, latest date, version list), we fetch all data in one call
2. **Parallel Processing:** 10 concurrent threads process API calls simultaneously, reducing total time by ~50%
3. **Incremental Display:** Gem results are shown immediately, then packages are scanned (better UX)

---

## Error Handling

- If a command fails → returns empty array (no dummy data)
- If API call fails → shows "N/A" for dates/counts
- If parsing fails → shows warning and uses empty data
- All errors are gracefully handled without crashing the scan



