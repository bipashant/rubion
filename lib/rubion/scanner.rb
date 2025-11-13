# frozen_string_literal: true

require 'json'
require 'open3'
require_relative 'reporter'
require 'net/http'
require 'uri'
require 'date'

module Rubion
  class Scanner
    class ScanResult
      attr_accessor :gem_vulnerabilities, :gem_versions, :package_vulnerabilities, :package_versions

      def initialize
        @gem_vulnerabilities = []
        @gem_versions = []
        @package_vulnerabilities = []
        @package_versions = []
      end
    end

    def initialize(project_path: Dir.pwd)
      @project_path = project_path
      @result = ScanResult.new
    end

    def scan
      puts "🔍 Scanning project at: #{@project_path}\n\n"
      
      scan_ruby_gems
      scan_npm_packages
      
      @result
    end

    def scan_incremental(options = { gems: true, packages: true })
      puts "🔍 Scanning project at: #{@project_path}\n\n"
      
      # Scan and display Ruby gems first (if enabled)
      if options[:gems]
        scan_ruby_gems
        
        # Print gem results immediately
        puts "\n"
        reporter = Reporter.new(@result)
        reporter.print_gem_vulnerabilities
        reporter.print_gem_versions
      end
      
      # Then scan NPM packages (if enabled)
      if options[:packages]
        puts "\n" if options[:gems]  # Add spacing if gems were scanned
        scan_npm_packages
      end
      
      @result
    end

    private

    def scan_ruby_gems
      return unless File.exist?(File.join(@project_path, 'Gemfile.lock'))
      
      # Check for vulnerabilities using bundler-audit
      check_gem_vulnerabilities
      
      # Check for outdated versions using bundle outdated (will show progress)
      check_gem_versions
    end

    def scan_npm_packages
      package_json = File.join(@project_path, 'package.json')
      return unless File.exist?(package_json)
      
      # Check for vulnerabilities using npm audit
      check_npm_vulnerabilities
      
      # Check for outdated versions using npm outdated (will show progress)
      check_npm_versions
    end

    def check_gem_vulnerabilities
      # Try to use bundler-audit if available
      stdout, stderr, status = Open3.capture3("bundle-audit check 2>&1", chdir: @project_path)
      
      # bundle-audit returns exit code 1 when vulnerabilities are found, 0 when none found
      # Always parse if there's output (vulnerabilities found) or if it succeeded (no vulnerabilities)
      if stdout.include?("vulnerabilities found") || stdout.include?("Name:") || status.success?
        parse_bundler_audit_output(stdout)
      else
        # No vulnerabilities found or bundler-audit not available
        @result.gem_vulnerabilities = []
      end
    rescue => e
      puts "  ⚠️  Could not run bundle-audit (#{e.message}). Skipping gem vulnerability check."
      @result.gem_vulnerabilities = []
    end

    def check_gem_versions
      stdout, stderr, status = Open3.capture3("bundle outdated --parseable", chdir: @project_path)
      
      if status.success? || !stdout.empty?
        parse_bundle_outdated_output(stdout)
      else
        # No outdated gems found
        @result.gem_versions = []
      end
    rescue => e
      puts "  ⚠️  Could not run bundle outdated (#{e.message}). Skipping gem version check."
      @result.gem_versions = []
    end

    def check_npm_vulnerabilities
      stdout, stderr, status = Open3.capture3("npm audit --json 2>&1", chdir: @project_path)
      
      begin
        data = JSON.parse(stdout)
        parse_npm_audit_output(data)
      rescue JSON::ParserError
        @result.package_vulnerabilities = []
      end
    rescue => e
      puts "  ⚠️  Could not run npm audit (#{e.message}). Skipping package vulnerability check."
      @result.package_vulnerabilities = []
    end

    def check_npm_versions
      stdout, stderr, status = Open3.capture3("npm outdated --json 2>&1", chdir: @project_path)
      
      begin
        data = JSON.parse(stdout) unless stdout.empty?
        parse_npm_outdated_output(data || {})
      rescue JSON::ParserError
        @result.package_versions = []
      end
    rescue => e
      puts "  ⚠️  Could not run npm outdated (#{e.message}). Skipping package version check."
      @result.package_versions = []
    end

    # Parsers

    def parse_bundler_audit_output(output)
      vulnerabilities = []
      current_gem = nil
      
      output.each_line do |line|
        line = line.strip
        next if line.empty?
        
        if line =~ /^Name: (.+)/
          current_gem = { gem: $1.strip }
        elsif line =~ /^Version: (.+)/ && current_gem
          current_gem[:version] = $1.strip
        elsif line =~ /^CVE: (.+)/ && current_gem
          current_gem[:advisory] = $1.strip
        elsif line =~ /^Advisory: (.+)/ && current_gem
          # Fallback for older bundle-audit versions
          current_gem[:advisory] = $1.strip
        elsif line =~ /^Criticality: (.+)/ && current_gem
          current_gem[:severity] = $1.strip
        elsif line =~ /^Title: (.+)/ && current_gem
          current_gem[:title] = $1.strip
          # Only add if we have at least name, version, and title
          if current_gem[:gem] && current_gem[:version] && current_gem[:title]
            vulnerabilities << current_gem
          end
          current_gem = nil
        end
      end
      
      # Handle case where vulnerability block ends without Title (use CVE as title)
      if current_gem && current_gem[:gem] && current_gem[:version]
        current_gem[:title] ||= current_gem[:advisory] || "Vulnerability detected"
        vulnerabilities << current_gem
      end
      
      @result.gem_vulnerabilities = vulnerabilities
    end

    def parse_bundle_outdated_output(output)
      versions = []
      lines_to_process = []
      
      # First pass: collect all lines to process
      output.each_line do |line|
        next if line.strip.empty?
        
        # Parse format: gem_name (newest version, installed version, requested version)
        if line =~ /^(.+?)\s+\(newest\s+(.+?),\s+installed\s+(.+?)(?:,|\))/
          lines_to_process << {
            gem_name: $1.strip,
            current_version: $3.strip,
            latest_version: $2.strip
          }
        end
      end
      
      total = lines_to_process.size
      
        # Second pass: process with progress counter
        lines_to_process.each_with_index do |line_data, index|
          print "\r📦 Checking Ruby gems... #{index + 1}/#{total}"
          $stdout.flush
          
          # Fetch release dates and version info from RubyGems API
          current_info = fetch_gem_version_info(line_data[:gem_name], line_data[:current_version])
          latest_info = fetch_gem_version_info(line_data[:gem_name], line_data[:latest_version])
          
          # Calculate time difference and version count
          time_diff = calculate_time_difference(current_info[:date], latest_info[:date])
          version_count = count_versions_between(line_data[:gem_name], line_data[:current_version], line_data[:latest_version])
          
          versions << {
            gem: line_data[:gem_name],
            current: line_data[:current_version],
            current_date: current_info[:date],
            latest: line_data[:latest_version],
            latest_date: latest_info[:date],
            time_diff: time_diff,
            version_count: version_count
          }
        end
      
      puts "\r📦 Checking Ruby gems... #{total}/#{total} ✓" if total > 0
      
      @result.gem_versions = versions
    end

    def parse_npm_audit_output(data)
      vulnerabilities = []
      
      if data['vulnerabilities'] && data['vulnerabilities'].is_a?(Hash)
        data['vulnerabilities'].each do |name, info|
          next unless info.is_a?(Hash)
          
          # Extract title from via array
          title = 'Vulnerability detected'
          if info['via'].is_a?(Array) && info['via'].first.is_a?(Hash)
            title = info['via'].first['title'] || title
          elsif info['via'].is_a?(String)
            title = info['via']
          end
          
          vulnerabilities << {
            package: name,
            version: info['range'] || info['version'] || 'unknown',
            severity: info['severity'] || 'unknown',
            title: title
          }
        end
      end
      
      @result.package_vulnerabilities = vulnerabilities
    rescue => e
      puts "  ⚠️  Error parsing npm audit data: #{e.message}"
      @result.package_vulnerabilities = []
    end

    def parse_npm_outdated_output(data)
      versions = []
      
      if data.is_a?(Hash)
        packages_to_process = []
        
        # First pass: collect all packages to process
        data.each do |name, info|
          next unless info.is_a?(Hash)
          
          packages_to_process << {
            name: name,
            current_version: info['current'] || 'unknown',
            latest_version: info['latest'] || 'unknown'
          }
        end
        
        total = packages_to_process.size
        
        # Second pass: process with progress counter
        packages_to_process.each_with_index do |pkg_data, index|
          print "\r📦 Checking NPM packages... #{index + 1}/#{total}"
          $stdout.flush
          
          # Fetch release dates from NPM registry
          current_info = fetch_npm_version_info(pkg_data[:name], pkg_data[:current_version])
          latest_info = fetch_npm_version_info(pkg_data[:name], pkg_data[:latest_version])
          
          # Calculate time difference and version count
          time_diff = calculate_time_difference(current_info[:date], latest_info[:date])
          version_count = count_npm_versions_between(pkg_data[:name], pkg_data[:current_version], pkg_data[:latest_version])
          
          versions << {
            package: pkg_data[:name],
            current: pkg_data[:current_version],
            current_date: current_info[:date],
            latest: pkg_data[:latest_version],
            latest_date: latest_info[:date],
            time_diff: time_diff,
            version_count: version_count
          }
        end
        
        puts "\r📦 Checking NPM packages... #{total}/#{total} ✓" if total > 0
      end
      
      @result.package_versions = versions
    rescue => e
      puts "  ⚠️  Error parsing npm outdated data: #{e.message}"
      @result.package_versions = []
    end

    # Dummy data for demonstration (commented out - only show real data)
    # Uncomment these methods if you need dummy data for testing

    # def dummy_gem_vulnerabilities
    #   [
    #     {
    #       gem: 'rails',
    #       version: '7.2.2.2',
    #       severity: 'Critical',
    #       advisory: 'CVE-2024-12345',
    #       title: 'ActiveRecord attack'
    #     },
    #     {
    #       gem: 'rack',
    #       version: '3.1.18',
    #       severity: 'High',
    #       advisory: 'CVE-2024-54321',
    #       title: 'Man in middle attack'
    #     },
    #     {
    #       gem: 'nokogiri',
    #       version: '1.10.4',
    #       severity: 'Medium',
    #       advisory: 'CVE-2021-30560',
    #       title: 'Update bundled libxml2 to v2.9.12'
    #     }
    #   ]
    # end

    # def dummy_gem_versions
    #   [
    #     { gem: 'sidekiq', current: '7.3.0', current_date: '3/5/2024', latest: '8.1.0', latest_date: '11/11/2024' },
    #     { gem: 'fastimage', current: '2.2.7', current_date: '2/2/2025', latest: '2.3.2', latest_date: '9/9/2025' },
    #     { gem: 'puma', current: '4.3.8', current_date: '1/15/2024', latest: '6.4.0', latest_date: '10/20/2024' },
    #     { gem: 'devise', current: '4.7.3', current_date: '3/10/2024', latest: '4.9.3', latest_date: '8/15/2024' },
    #     { gem: 'rspec-rails', current: '4.0.2', current_date: '2/5/2024', latest: '6.1.0', latest_date: '12/1/2024' }
    #   ]
    # end

    # def dummy_npm_vulnerabilities
    #   [
    #     {
    #       package: 'moment',
    #       version: '1.2.3',
    #       severity: 'high',
    #       title: 'Wrong timezone date'
    #     },
    #     {
    #       package: 'axios',
    #       version: '0.21.1',
    #       severity: 'high',
    #       title: 'Server-Side Request Forgery in axios'
    #     },
    #     {
    #       package: 'minimist',
    #       version: '1.2.5',
    #       severity: 'critical',
    #       title: 'Prototype Pollution in minimist'
    #     }
    #   ]
    # end

    # def dummy_npm_versions
    #   [
    #     { package: 'jquery', current: '3.7.1', current_date: '4/5/2024', latest: '3.9.1', latest_date: '10/11/2025' },
    #     { package: 'vue', current: '2.6.12', current_date: '5/15/2024', latest: '3.4.3', latest_date: '11/20/2024' },
    #     { package: 'webpack', current: '4.46.0', current_date: '3/8/2024', latest: '5.89.0', latest_date: '9/25/2024' },
    #     { package: 'eslint', current: '7.32.0', current_date: '2/12/2024', latest: '8.56.0', latest_date: '12/5/2024' },
    #     { package: '@babel/core', current: '7.15.0', current_date: '4/20/2024', latest: '7.23.6', latest_date: '10/30/2024' }
    #   ]
    # end

    # Fetch gem version info (date) from RubyGems API
    def fetch_gem_version_info(gem_name, version)
      return { date: 'N/A' } if version == 'unknown' || gem_name.nil?
      
      uri = URI("https://rubygems.org/api/v1/versions/#{gem_name}.json")
      
      # Set timeout to avoid hanging
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # Skip SSL verification
      http.open_timeout = 2
      http.read_timeout = 3
      
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      
      return { date: 'N/A' } unless response.is_a?(Net::HTTPSuccess)
      
      versions = JSON.parse(response.body)
      version_info = versions.find { |v| v['number'] == version }
      
      if version_info && version_info['created_at']
        date = DateTime.parse(version_info['created_at'])
        { date: date.strftime('%-m/%-d/%Y') }  # Format: 3/5/2024
      else
        { date: 'N/A' }
      end
    rescue => e
      puts "  Debug: Error fetching date for #{gem_name} #{version}: #{e.message}" if ENV['DEBUG']
      { date: 'N/A' }
    end

    # Count versions between current and latest
    def count_versions_between(gem_name, current_version, latest_version)
      return 'N/A' if current_version == 'unknown' || latest_version == 'unknown' || gem_name.nil?
      return 0 if current_version == latest_version
      
      uri = URI("https://rubygems.org/api/v1/versions/#{gem_name}.json")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = 2
      http.read_timeout = 3
      
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      
      return 'N/A' unless response.is_a?(Net::HTTPSuccess)
      
      all_versions = JSON.parse(response.body)
      version_numbers = all_versions.map { |v| v['number'] }
      
      # Find indices of current and latest versions
      current_idx = version_numbers.index(current_version)
      latest_idx = version_numbers.index(latest_version)
      
      return 'N/A' if current_idx.nil? || latest_idx.nil?
      
      # Count versions between (exclusive of current, inclusive of latest)
      (latest_idx - current_idx).abs
    rescue => e
      puts "  Debug: Error counting versions for #{gem_name}: #{e.message}" if ENV['DEBUG']
      'N/A'
    end

    # Calculate time difference between two dates
    def calculate_time_difference(date1_str, date2_str)
      return 'N/A' if date1_str == 'N/A' || date2_str == 'N/A'
      
      begin
        # Parse dates - convert "8/13/2025" format to Date object
        # Split by / and create Date object
        parts1 = date1_str.split('/').map(&:to_i)
        parts2 = date2_str.split('/').map(&:to_i)
        
        date1 = Date.new(parts1[2], parts1[0], parts1[1])
        date2 = Date.new(parts2[2], parts2[0], parts2[1])
        
        # Always use the later date minus the earlier date
        diff = (date2 - date1).to_i.abs
        
        if diff < 30
          "#{diff} day#{diff != 1 ? 's' : ''}"
        elsif diff < 365
          months = (diff / 30.0).round
          "#{months} month#{months != 1 ? 's' : ''}"
        else
          years = (diff / 365.0).round(1)
          if years == years.to_i
            "#{years.to_i} year#{years.to_i != 1 ? 's' : ''}"
          else
            "#{years} years"
          end
        end
      rescue => e
        puts "  Debug: Error calculating time diff: #{e.message}" if ENV['DEBUG']
        'N/A'
      end
    end

    # Fetch npm package version info (date) from NPM registry
    def fetch_npm_version_info(package_name, version)
      return { date: 'N/A' } if version == 'unknown' || package_name.nil?
      
      # Encode package name for URL (handles scoped packages like @babel/core)
      encoded_name = URI.encode_www_form_component(package_name)
      uri = URI("https://registry.npmjs.org/#{encoded_name}")
      
      # Set timeout to avoid hanging
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # Skip SSL verification
      http.open_timeout = 2
      http.read_timeout = 3
      
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      
      return { date: 'N/A' } unless response.is_a?(Net::HTTPSuccess)
      
      data = JSON.parse(response.body)
      
      if data['time'] && data['time'][version]
        date = DateTime.parse(data['time'][version])
        { date: date.strftime('%-m/%-d/%Y') }  # Format: 3/5/2024
      else
        { date: 'N/A' }
      end
    rescue => e
      puts "  Debug: Error fetching date for #{package_name} #{version}: #{e.message}" if ENV['DEBUG']
      { date: 'N/A' }
    end

    # Count NPM versions between current and latest
    def count_npm_versions_between(package_name, current_version, latest_version)
      return 'N/A' if current_version == 'unknown' || latest_version == 'unknown' || package_name.nil?
      return 0 if current_version == latest_version
      
      encoded_name = URI.encode_www_form_component(package_name)
      uri = URI("https://registry.npmjs.org/#{encoded_name}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = 2
      http.read_timeout = 3

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      return 'N/A' unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      
      return 'N/A' unless data['time'] && data['versions']
      
      # Get all version numbers sorted by release date
      version_times = data['time'].select { |k, v| k != 'created' && k != 'modified' && data['versions'][k] }
      sorted_versions = version_times.sort_by { |k, v| DateTime.parse(v) }.map(&:first)
      
      current_idx = sorted_versions.index(current_version)
      latest_idx = sorted_versions.index(latest_version)
      
      return 'N/A' if current_idx.nil? || latest_idx.nil?
      
      # Count versions between (exclusive of current, inclusive of latest)
      (latest_idx - current_idx).abs
    rescue => e
      puts "  Debug: Error counting versions for #{package_name}: #{e.message}" if ENV['DEBUG']
      'N/A'
    end
  end
end

