# frozen_string_literal: true

require 'terminal-table'

module Rubion
  class Reporter
    def initialize(scan_result, sort_by: 'Behind By(Time)', sort_desc: true)
      @result = scan_result
      @sort_by = sort_by
      @sort_desc = sort_desc
    end

    def report
      print_header
      _print_gem_vulnerabilities
      _print_gem_versions
      _print_package_vulnerabilities
      _print_package_versions
      print_summary
    end

    # Public methods for incremental reporting
    def print_gem_vulnerabilities
      _print_gem_vulnerabilities
    end

    def print_gem_versions
      _print_gem_versions
    end

    def print_package_vulnerabilities
      _print_package_vulnerabilities
    end

    def print_package_versions
      _print_package_versions
    end

    private

    def print_header
      # Simplified header
      puts "\n"
    end

    def _print_gem_vulnerabilities
      if @result.gem_vulnerabilities.empty?
        puts "  ✅ No vulnerabilities found!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.headings = %w[Level Name Version Vulnerability]

        @result.gem_vulnerabilities.each do |vuln|
          t.add_row [
            severity_with_icon(vuln[:severity]),
            vuln[:gem],
            vuln[:version],
            truncate(vuln[:title], 50)
          ]
        end
      end

      puts table
      puts "\n"
    end

    def _print_gem_versions
      puts "Gem Versions:\n\n"

      if @result.gem_versions.empty?
        puts "  ✅ All gems are up to date!\n\n"
        return
      end

      # Filter to only direct dependencies if flag is set
      versions = @result.gem_versions.dup
      versions = versions.select { |gem| gem[:direct] } if @exclude_dependencies

      if versions.empty?
        puts "  ✅ No direct dependencies found!\n\n"
        return
      end

      # Sort if sort_by is specified
      versions = sort_versions(versions, :gem) if @sort_by

      table = Terminal::Table.new do |t|
        t.headings = ['Name', 'Current', 'Date', 'Latest', 'Date', 'Behind By(Time)', 'Behind By(Versions)']

        versions.each do |gem|
          # Make direct dependencies bold
          gem_name = gem[:direct] ? bold(gem[:gem]) : gem[:gem]

          t.add_row [
            gem_name,
            gem[:current],
            gem[:current_date] || 'N/A',
            gem[:latest],
            gem[:latest_date] || 'N/A',
            gem[:time_diff] || 'N/A',
            gem[:version_count] || 'N/A'
          ]
        end
      end

      puts table
      puts "\n"
    end

    def _print_package_vulnerabilities
      puts "Package Vulnerabilities:\n\n"

      if @result.package_vulnerabilities.empty?
        puts "  ✅ No vulnerabilities found!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.headings = %w[Level Name Version Vulnerability]

        @result.package_vulnerabilities.each do |vuln|
          t.add_row [
            severity_with_icon(vuln[:severity]),
            vuln[:package],
            vuln[:version],
            truncate(vuln[:title], 50)
          ]
        end
      end

      puts table
      puts "\n"
    end

    def _print_package_versions
      puts "Package Versions:\n\n"

      if @result.package_versions.empty?
        puts "  ✅ All packages are up to date!\n\n"
        return
      end

      # Filter to only direct dependencies if flag is set
      versions = @result.package_versions.dup
      versions = versions.select { |pkg| pkg[:direct] } if @exclude_dependencies

      if versions.empty?
        puts "  ✅ No direct dependencies found!\n\n"
        return
      end

      # Sort if sort_by is specified
      versions = sort_versions(versions, :package) if @sort_by

      table = Terminal::Table.new do |t|
        t.headings = ['Name', 'Current', 'Date', 'Latest', 'Date', 'Behind By(Time)', 'Behind By(Versions)']

        versions.each do |pkg|
          # Make direct dependencies bold
          package_name = pkg[:direct] ? bold(pkg[:package]) : pkg[:package]

          t.add_row [
            package_name,
            pkg[:current],
            pkg[:current_date] || 'N/A',
            pkg[:latest],
            pkg[:latest_date] || 'N/A',
            pkg[:time_diff] || 'N/A',
            pkg[:version_count] || 'N/A'
          ]
        end
      end

      puts table
      puts "\n"
    end

    def print_summary
      # Minimal summary at the end
      puts "\n"
    end

    # Helpers

    def severity_with_icon(severity)
      severity_str = severity.to_s.capitalize

      case severity.to_s.downcase
      when 'critical'
        "🔴 #{severity_str}"
      when 'high'
        "🟠 #{severity_str}"
      when 'medium', 'moderate'
        "🟡 #{severity_str}"
      when 'low'
        "🟢 #{severity_str}"
      when 'unknown'
        "⚪ #{severity_str}"
      else
        severity_str
      end
    end

    def colorize_severity(severity)
      case severity.to_s.downcase
      when 'critical'
        "🔴 #{severity}"
      when 'high'
        "🟠 #{severity}"
      when 'medium', 'moderate'
        "🟡 #{severity}"
      when 'low'
        "🟢 #{severity}"
      else
        severity
      end
    end

    def colorize_count(count)
      count > 0 ? "🔴 #{count}" : "✅ #{count}"
    end

    def truncate(text, length = 50)
      return text if text.length <= length

      "#{text[0..(length - 3)]}..."
    end

    # Make text bold using ANSI escape codes
    def bold(text)
      "\033[1m#{text}\033[0m"
    end

    def version_difference(current, latest)
      # Simple version difference calculation
      current_parts = current.split('.').map(&:to_i)
      latest_parts = latest.split('.').map(&:to_i)

      major_diff = (latest_parts[0] || 0) - (current_parts[0] || 0)
      minor_diff = (latest_parts[1] || 0) - (current_parts[1] || 0)
      patch_diff = (latest_parts[2] || 0) - (current_parts[2] || 0)

      if major_diff > 0
        "#{major_diff} major"
      elsif minor_diff > 0
        "#{minor_diff} minor"
      elsif patch_diff > 0
        "#{patch_diff} patch"
      else
        'up to date'
      end
    rescue StandardError
      'unknown'
    end

    # Sort versions array based on the specified column
    def sort_versions(versions, name_key)
      return versions unless @sort_by

      column = @sort_by.strip.downcase
      name_key_sym = name_key # :gem or :package

      # Normalize column name - default to 'name' if not recognized
      normalized_column = case column
                          when 'name', 'current', 'date', 'latest',
                               'behind by(time)', 'behind by time', 'time',
                               'behind by(versions)', 'behind by versions', 'versions'
                            column
                          else
                            'name' # Default to name sorting
                          end

      sorted = versions.sort_by do |item|
        case normalized_column
        when 'name'
          # Remove ANSI codes for sorting
          name = item[name_key_sym].to_s
          name = name.gsub(/\033\[[0-9;]*m/, '') # Remove ANSI escape codes
          name.downcase
        when 'current'
          parse_version_for_sort(item[:current])
        when 'date'
          # Sort by current_date (first Date column)
          parse_date_for_sort(item[:current_date])
        when 'latest'
          parse_version_for_sort(item[:latest])
        when 'behind by(time)', 'behind by time', 'time'
          parse_time_for_sort(item[:time_diff])
        when 'behind by(versions)', 'behind by versions', 'versions'
          parse_version_count_for_sort(item[:version_count])
        end
      end

      # Reverse if descending order requested
      @sort_desc ? sorted.reverse : sorted
    end

    # Parse version string for sorting (handles semantic versions)
    def parse_version_for_sort(version_str)
      return [0, 0, 0, ''] if version_str.nil? || version_str == 'N/A' || version_str == 'unknown'

      # Handle version strings like "1.2.3", "1.2.3.4", "1.2.3-beta", etc.
      parts = version_str.to_s.split(/[.-]/)
      major = parts[0].to_i
      minor = parts[1].to_i
      patch = parts[2].to_i
      suffix = parts[3..-1].join('') if parts.length > 3

      [major, minor, patch, suffix || '']
    end

    # Parse date string for sorting (handles M/D/YYYY format)
    def parse_date_for_sort(date_str)
      return [0, 0, 0] if date_str.nil? || date_str == 'N/A'

      begin
        parts = date_str.split('/').map(&:to_i)
        return [parts[2] || 0, parts[0] || 0, parts[1] || 0] if parts.length == 3
      rescue StandardError
        # If parsing fails, return a date that sorts last
      end

      [0, 0, 0]
    end

    # Parse time difference string for sorting (e.g., "1 year", "3 months", "5 days")
    def parse_time_for_sort(time_str)
      return [0, 0] if time_str.nil? || time_str == 'N/A'

      time_str = time_str.to_s.downcase.strip

      # Extract number and unit
      match = time_str.match(/(\d+(?:\.\d+)?)\s*(year|month|day|years|months|days)/)
      return [0, 0] unless match

      value = match[1].to_f
      unit = match[2].to_s.downcase

      # Convert to days for comparison
      days = case unit
             when /year/
               value * 365
             when /month/
               value * 30
             when /day/
               value
             else
               0
             end

      [days.to_i, value]
    end

    # Parse version count for sorting
    def parse_version_count_for_sort(count)
      return 0 if count.nil? || count == 'N/A' || count == 'unknown'

      count.to_i
    end
  end
end
