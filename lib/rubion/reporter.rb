# frozen_string_literal: true

require 'terminal-table'

module Rubion
  class Reporter
    def initialize(scan_result)
      @result = scan_result
    end

    def report
      print_header
      print_gem_vulnerabilities
      print_gem_versions
      print_package_vulnerabilities
      print_package_versions
      print_summary
    end

    private

    def print_header
      puts "\n"
      puts "=" * 80
      puts "  🔒 RUBION SECURITY & VERSION SCAN REPORT"
      puts "=" * 80
      puts "\n"
    end

    def print_gem_vulnerabilities
      puts "📛 GEM VULNERABILITIES\n\n"
      
      if @result.gem_vulnerabilities.empty?
        puts "  ✅ No vulnerabilities found!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.title = "Ruby Gem Vulnerabilities"
        t.headings = ['Gem', 'Version', 'Severity', 'Advisory', 'Title']
        t.style = { width: 120, border_x: '=', border_i: '=' }
        
        @result.gem_vulnerabilities.each do |vuln|
          t.add_row [
            vuln[:gem],
            vuln[:version],
            colorize_severity(vuln[:severity]),
            vuln[:advisory],
            truncate(vuln[:title], 40)
          ]
        end
      end
      
      puts table
      puts "\n"
    end

    def print_gem_versions
      puts "📦 GEM VERSIONS (Outdated)\n\n"
      
      if @result.gem_versions.empty?
        puts "  ✅ All gems are up to date!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.title = "Outdated Ruby Gems"
        t.headings = ['Gem', 'Current Version', 'Latest Version', 'Behind By']
        t.style = { width: 100 }
        
        @result.gem_versions.each do |gem|
          behind = version_difference(gem[:current], gem[:latest])
          t.add_row [
            gem[:gem],
            gem[:current],
            gem[:latest],
            behind
          ]
        end
      end
      
      puts table
      puts "\n"
    end

    def print_package_vulnerabilities
      puts "📛 NPM PACKAGE VULNERABILITIES\n\n"
      
      if @result.package_vulnerabilities.empty?
        puts "  ✅ No vulnerabilities found!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.title = "NPM Package Vulnerabilities"
        t.headings = ['Package', 'Version', 'Severity', 'Title']
        t.style = { width: 120, border_x: '=', border_i: '=' }
        
        @result.package_vulnerabilities.each do |vuln|
          t.add_row [
            vuln[:package],
            vuln[:version],
            colorize_severity(vuln[:severity]),
            truncate(vuln[:title], 50)
          ]
        end
      end
      
      puts table
      puts "\n"
    end

    def print_package_versions
      puts "📦 NPM PACKAGE VERSIONS (Outdated)\n\n"
      
      if @result.package_versions.empty?
        puts "  ✅ All packages are up to date!\n\n"
        return
      end

      table = Terminal::Table.new do |t|
        t.title = "Outdated NPM Packages"
        t.headings = ['Package', 'Current Version', 'Latest Version', 'Behind By']
        t.style = { width: 100 }
        
        @result.package_versions.each do |pkg|
          behind = version_difference(pkg[:current], pkg[:latest])
          t.add_row [
            pkg[:package],
            pkg[:current],
            pkg[:latest],
            behind
          ]
        end
      end
      
      puts table
      puts "\n"
    end

    def print_summary
      total_vulns = @result.gem_vulnerabilities.count + @result.package_vulnerabilities.count
      total_outdated = @result.gem_versions.count + @result.package_versions.count
      
      puts "=" * 80
      puts "  📊 SUMMARY"
      puts "=" * 80
      puts "  Total Vulnerabilities: #{colorize_count(total_vulns)}"
      puts "  Total Outdated: #{total_outdated}"
      puts "=" * 80
      puts "\n"
      
      if total_vulns > 0
        puts "⚠️  ACTION REQUIRED: Please update vulnerable dependencies!"
      else
        puts "✅ No vulnerabilities found. Great job keeping dependencies secure!"
      end
      
      puts "\n"
    end

    # Helpers

    def colorize_severity(severity)
      case severity.to_s.downcase
      when 'critical'
        "🔴 #{severity}"
      when 'high'
        "🟠 #{severity}"
      when 'medium'
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

