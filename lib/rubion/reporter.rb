# frozen_string_literal: true

require 'terminal-table'

module Rubion
  class Reporter
    def initialize(scan_result)
      @result = scan_result
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

    def _print_gem_vulnerabilities
      puts "Gem Vulnerabilities:\n\n"
      
      if @result.gem_vulnerabilities.empty?
        puts "  ✅ No vulnerabilities found!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.headings = ['Level', 'Name', 'Version', 'Vulnerability']
        
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
        t.headings = ['Level', 'Name', 'Version', 'Vulnerability']
        
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

      table = Terminal::Table.new do |t|
        t.headings = ['Name', 'Current', 'Date', 'Latest', 'Date', 'Behind By', 'Versions']
        
        @result.gem_versions.each do |gem|
          t.add_row [
            gem[:gem],
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
        t.headings = ['Level', 'Name', 'Version', 'Vulnerability']
        
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

      table = Terminal::Table.new do |t|
        t.headings = ['Name', 'Current', 'Date', 'Latest', 'Date', 'Behind By', 'Versions']
        
        @result.package_versions.each do |pkg|
          t.add_row [
            pkg[:package],
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
      "#{text[0..length-3]}..."
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
        "up to date"
      end
    rescue
      "unknown"
    end
  end
end

