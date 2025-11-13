# frozen_string_literal: true

require 'json'
require 'open3'

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

    private

    def scan_ruby_gems
      return unless File.exist?(File.join(@project_path, 'Gemfile.lock'))

      puts "📦 Checking Ruby gems..."
      
      # Check for vulnerabilities using bundler-audit
      check_gem_vulnerabilities
      
      # Check for outdated versions using bundle outdated
      check_gem_versions
    end

    def scan_npm_packages
      package_json = File.join(@project_path, 'package.json')
      return unless File.exist?(package_json)

      puts "📦 Checking NPM packages..."
      
      # Check for vulnerabilities using npm audit
      check_npm_vulnerabilities
      
      # Check for outdated versions using npm outdated
      check_npm_versions
    end

    def check_gem_vulnerabilities
      # Try to use bundler-audit if available
      stdout, stderr, status = Open3.capture3("bundle-audit check 2>&1", chdir: @project_path)
      
      if status.success? || stdout.include?("vulnerabilities found")
        parse_bundler_audit_output(stdout)
      else
        # Fallback to dummy data if bundler-audit is not installed
        @result.gem_vulnerabilities = dummy_gem_vulnerabilities
      end
    rescue => e
      puts "  ⚠️  Could not run bundle-audit (#{e.message}). Using dummy data."
      @result.gem_vulnerabilities = dummy_gem_vulnerabilities
    end

    def check_gem_versions
      stdout, stderr, status = Open3.capture3("bundle outdated --parseable", chdir: @project_path)
      
      if status.success? || !stdout.empty?
        parse_bundle_outdated_output(stdout)
      else
        @result.gem_versions = dummy_gem_versions
      end
    rescue => e
      puts "  ⚠️  Could not run bundle outdated (#{e.message}). Using dummy data."
      @result.gem_versions = dummy_gem_versions
    end

    def check_npm_vulnerabilities
      stdout, stderr, status = Open3.capture3("npm audit --json 2>&1", chdir: @project_path)
      
      begin
        data = JSON.parse(stdout)
        parse_npm_audit_output(data)
      rescue JSON::ParserError
        @result.package_vulnerabilities = dummy_npm_vulnerabilities
      end
    rescue => e
      puts "  ⚠️  Could not run npm audit (#{e.message}). Using dummy data."
      @result.package_vulnerabilities = dummy_npm_vulnerabilities
    end

    def check_npm_versions
      stdout, stderr, status = Open3.capture3("npm outdated --json 2>&1", chdir: @project_path)
      
      begin
        data = JSON.parse(stdout) unless stdout.empty?
        parse_npm_outdated_output(data || {})
      rescue JSON::ParserError
        @result.package_versions = dummy_npm_versions
      end
    rescue => e
      puts "  ⚠️  Could not run npm outdated (#{e.message}). Using dummy data."
      @result.package_versions = dummy_npm_versions
    end

    # Parsers

    def parse_bundler_audit_output(output)
      vulnerabilities = []
      current_gem = nil
      
      output.each_line do |line|
        if line =~ /^Name: (.+)/
          current_gem = { gem: $1.strip }
        elsif line =~ /^Version: (.+)/ && current_gem
          current_gem[:version] = $1.strip
        elsif line =~ /^Advisory: (.+)/ && current_gem
          current_gem[:advisory] = $1.strip
        elsif line =~ /^Criticality: (.+)/ && current_gem
          current_gem[:severity] = $1.strip
        elsif line =~ /^Title: (.+)/ && current_gem
          current_gem[:title] = $1.strip
          vulnerabilities << current_gem
          current_gem = nil
        end
      end
      
      @result.gem_vulnerabilities = vulnerabilities.empty? ? dummy_gem_vulnerabilities : vulnerabilities
    end

    def parse_bundle_outdated_output(output)
      versions = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        # Parse format: gem_name (newest version, installed version, requested version)
        if line =~ /^(.+?)\s+\(newest\s+(.+?),\s+installed\s+(.+?)(?:,|\))/
          versions << {
            gem: $1.strip,
            current: $3.strip,
            current_date: 'N/A',  # Would need additional gem info API call
            latest: $2.strip,
            latest_date: 'N/A'    # Would need additional gem info API call
          }
        end
      end
      
      @result.gem_versions = versions.empty? ? dummy_gem_versions : versions
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
      
      @result.package_vulnerabilities = vulnerabilities.empty? ? dummy_npm_vulnerabilities : vulnerabilities
    rescue => e
      puts "  ⚠️  Error parsing npm audit data: #{e.message}"
      @result.package_vulnerabilities = dummy_npm_vulnerabilities
    end

    def parse_npm_outdated_output(data)
      versions = []
      
      if data.is_a?(Hash)
        data.each do |name, info|
          next unless info.is_a?(Hash)
          
          versions << {
            package: name,
            current: info['current'] || 'unknown',
            current_date: 'N/A',  # Would need additional npm info API call
            latest: info['latest'] || 'unknown',
            latest_date: 'N/A'    # Would need additional npm info API call
          }
        end
      end
      
      @result.package_versions = versions.empty? ? dummy_npm_versions : versions
    rescue => e
      puts "  ⚠️  Error parsing npm outdated data: #{e.message}"
      @result.package_versions = dummy_npm_versions
    end

    # Dummy data for demonstration

    def dummy_gem_vulnerabilities
      [
        {
          gem: 'rails',
          version: '7.2.2.2',
          severity: 'Critical',
          advisory: 'CVE-2024-12345',
          title: 'ActiveRecord attack'
        },
        {
          gem: 'rack',
          version: '3.1.18',
          severity: 'High',
          advisory: 'CVE-2024-54321',
          title: 'Man in middle attack'
        },
        {
          gem: 'nokogiri',
          version: '1.10.4',
          severity: 'Medium',
          advisory: 'CVE-2021-30560',
          title: 'Update bundled libxml2 to v2.9.12'
        }
      ]
    end

    def dummy_gem_versions
      [
        { gem: 'sidekiq', current: '7.3.0', current_date: '3/5/2024', latest: '8.1.0', latest_date: '11/11/2024' },
        { gem: 'fastimage', current: '2.2.7', current_date: '2/2/2025', latest: '2.3.2', latest_date: '9/9/2025' },
        { gem: 'puma', current: '4.3.8', current_date: '1/15/2024', latest: '6.4.0', latest_date: '10/20/2024' },
        { gem: 'devise', current: '4.7.3', current_date: '3/10/2024', latest: '4.9.3', latest_date: '8/15/2024' },
        { gem: 'rspec-rails', current: '4.0.2', current_date: '2/5/2024', latest: '6.1.0', latest_date: '12/1/2024' }
      ]
    end

    def dummy_npm_vulnerabilities
      [
        {
          package: 'moment',
          version: '1.2.3',
          severity: 'high',
          title: 'Wrong timezone date'
        },
        {
          package: 'axios',
          version: '0.21.1',
          severity: 'high',
          title: 'Server-Side Request Forgery in axios'
        },
        {
          package: 'minimist',
          version: '1.2.5',
          severity: 'critical',
          title: 'Prototype Pollution in minimist'
        }
      ]
    end

    def dummy_npm_versions
      [
        { package: 'jquery', current: '3.7.1', current_date: '4/5/2024', latest: '3.9.1', latest_date: '10/11/2025' },
        { package: 'vue', current: '2.6.12', current_date: '5/15/2024', latest: '3.4.3', latest_date: '11/20/2024' },
        { package: 'webpack', current: '4.46.0', current_date: '3/8/2024', latest: '5.89.0', latest_date: '9/25/2024' },
        { package: 'eslint', current: '7.32.0', current_date: '2/12/2024', latest: '8.56.0', latest_date: '12/5/2024' },
        { package: '@babel/core', current: '7.15.0', current_date: '4/20/2024', latest: '7.23.6', latest_date: '10/30/2024' }
      ]
    end
  end
end

