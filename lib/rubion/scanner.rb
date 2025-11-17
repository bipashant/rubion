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

    def initialize(project_path: Dir.pwd, package_manager: nil)
      @project_path = project_path
      @result = ScanResult.new
      @package_manager = package_manager
      @package_manager_detected = false
      @direct_gems = nil
      @direct_packages = nil
    end

    def scan
      puts "🔍 Scanning project at: #{@project_path}\n\n"

      scan_ruby_gems
      scan_npm_packages

      @result
    end

    def scan_incremental(options = { gems: true, packages: true, sort_by: 'Behind By(Time)', sort_desc: true,
                                     exclude_dependencies: false })
      puts "🔍 Scanning project at: #{@project_path}\n\n"

      # Scan and display Ruby gems first (if enabled)
      if options[:gems]
        scan_ruby_gems

        # Print gem results immediately
        puts "\n"
        reporter = Reporter.new(@result, sort_by: options[:sort_by], sort_desc: options[:sort_desc],
                                         exclude_dependencies: options[:exclude_dependencies])
        reporter.print_gem_vulnerabilities
        reporter.print_gem_versions
      end

      # Then scan NPM packages (if enabled)
      if options[:packages]
        puts "\n" if options[:gems] # Add spacing if gems were scanned
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

      # Detect package manager if not already set
      unless @package_manager_detected
        @package_manager ||= detect_package_manager
        @package_manager_detected = true
      end

      unless @package_manager
        puts '  ⚠️  Neither npm nor yarn is available. Skipping package scanning.'
        return
      end

      # Check for vulnerabilities using package manager audit
      check_npm_vulnerabilities

      # Check for outdated versions using package manager outdated (will show progress)
      check_npm_versions
    end

    def check_gem_vulnerabilities
      # Try to use bundler-audit if available
      stdout, stderr, status = Open3.capture3('bundle-audit check 2>&1', chdir: @project_path)

      # bundle-audit returns exit code 1 when vulnerabilities are found, 0 when none found
      # Exit code 1 is expected when vulnerabilities exist, so we still parse the output
      # Exit code 0 means no vulnerabilities found
      # Any other exit code or error means the command failed
      if status.exitstatus.nil? || status.exitstatus == 127 || stderr.include?('command not found') || stdout.include?('command not found')
        # Command not found - show friendly message and skip vulnerability check
        puts "\n  ℹ️  bundle-audit is not installed. Skipping gem vulnerability check."
        puts "     To enable vulnerability scanning, install it with: gem install bundler-audit\n"
        @result.gem_vulnerabilities = []
      elsif status.exitstatus == 1 || status.success? || (!stdout.empty? && (stdout.include?('vulnerabilities found') || stdout.include?('Name:')))
        # Exit code 1 (vulnerabilities found) or 0 (no vulnerabilities) - parse output
        # Also try to parse if output looks valid even if exit code is unexpected
        parse_bundler_audit_output(stdout)
      else
        # Unexpected exit code
        raise "bundle-audit failed with exit code #{status.exitstatus}. Output: #{stdout}#{unless stderr.empty?
                                                                                             "\nError: #{stderr}"
                                                                                           end}"
      end
    end

    def check_gem_versions
      stdout, stderr, status = Open3.capture3('bundle outdated --parseable', chdir: @project_path)

      if status.success?
        # Command succeeded - parse output (may be empty if all gems are up to date)
        parse_bundle_outdated_output(stdout)
      elsif status.exitstatus.nil?
        # Command not found or failed to execute
        raise "bundle outdated command failed or is not available. Error: #{stderr}"
      else
        # Command failed with non-zero exit code
        raise "bundle outdated failed with exit code #{status.exitstatus}. Output: #{stdout}#{unless stderr.empty?
                                                                                                "\nError: #{stderr}"
                                                                                              end}"
      end
    end

    def check_npm_vulnerabilities
      return unless @package_manager

      command = "#{@package_manager} audit --json 2>&1"
      stdout, stderr, status = Open3.capture3(command, chdir: @project_path)

      if status.exitstatus.nil?
        # Command not found or failed to execute
        raise "#{@package_manager} audit command failed or is not available. Error: #{stderr}"
      elsif !status.success? && status.exitstatus != 1
        # Exit code 1 is expected when vulnerabilities are found, other non-zero codes are errors
        raise "#{@package_manager} audit failed with exit code #{status.exitstatus}. Output: #{stdout}#{unless stderr.empty?
                                                                                                          "\nError: #{stderr}"
                                                                                                        end}"
      end

      begin
        data = JSON.parse(stdout)
        parse_npm_audit_output(data)
      rescue JSON::ParserError => e
        raise "Failed to parse #{@package_manager} audit JSON output: #{e.message}. Raw output: #{stdout}"
      end
    end

    def check_npm_versions
      return unless @package_manager

      # Yarn v1 doesn't support --json flag, so handle it differently
      if @package_manager == 'yarn'
        check_yarn_outdated
      else
        check_npm_outdated
      end
    end

    def check_npm_outdated
      command = 'npm outdated --json 2>&1'
      stdout, stderr, status = Open3.capture3(command, chdir: @project_path)

      if status.exitstatus.nil?
        # Command not found or failed to execute
        raise "npm outdated command failed or is not available. Error: #{stderr}"
      elsif !status.success? && status.exitstatus != 1
        # Exit code 1 is expected when packages are outdated, other non-zero codes are errors
        raise "npm outdated failed with exit code #{status.exitstatus}. Output: #{stdout}#{unless stderr.empty?
                                                                                             "\nError: #{stderr}"
                                                                                           end}"
      end

      begin
        data = JSON.parse(stdout) unless stdout.empty?
        parse_npm_outdated_output(data || {})
      rescue JSON::ParserError => e
        raise "Failed to parse npm outdated JSON output: #{e.message}. Raw output: #{stdout}"
      end
    end

    def check_yarn_outdated
      # Yarn v1 doesn't support --json, so parse text output
      command = 'yarn outdated 2>&1'
      stdout, stderr, status = Open3.capture3(command, chdir: @project_path)

      if status.exitstatus.nil?
        # Command not found or failed to execute
        raise "yarn outdated command failed or is not available. Error: #{stderr}"
      elsif !status.success? && status.exitstatus != 1
        # Exit code 1 is expected when packages are outdated, other non-zero codes are errors
        raise "yarn outdated failed with exit code #{status.exitstatus}. Output: #{stdout}#{unless stderr.empty?
                                                                                              "\nError: #{stderr}"
                                                                                            end}"
      end

      begin
        parse_yarn_outdated_output(stdout)
      rescue StandardError => e
        raise "Failed to parse yarn outdated output: #{e.message}. Raw output: #{stdout}"
      end
    end

    # Parsers

    def parse_bundler_audit_output(output)
      vulnerabilities = []
      current_gem = nil

      output.each_line do |line|
        line = line.strip
        next if line.empty?

        if line =~ /^Name: (.+)/
          current_gem = { gem: ::Regexp.last_match(1).strip }
        elsif line =~ /^Version: (.+)/ && current_gem
          current_gem[:version] = ::Regexp.last_match(1).strip
        elsif line =~ /^CVE: (.+)/ && current_gem
          current_gem[:advisory] = ::Regexp.last_match(1).strip
        elsif line =~ /^Advisory: (.+)/ && current_gem
          # Fallback for older bundle-audit versions
          current_gem[:advisory] = ::Regexp.last_match(1).strip
        elsif line =~ /^Criticality: (.+)/ && current_gem
          current_gem[:severity] = ::Regexp.last_match(1).strip
        elsif line =~ /^Title: (.+)/ && current_gem
          current_gem[:title] = ::Regexp.last_match(1).strip
          # Only add if we have at least name, version, and title
          vulnerabilities << current_gem if current_gem[:gem] && current_gem[:version] && current_gem[:title]
          current_gem = nil
        end
      end

      # Handle case where vulnerability block ends without Title (use CVE as title)
      if current_gem && current_gem[:gem] && current_gem[:version]
        current_gem[:title] ||= current_gem[:advisory] || 'Vulnerability detected'
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
        next unless line =~ /^(.+?)\s+\(newest\s+(.+?),\s+installed\s+(.+?)(?:,|\))/

        lines_to_process << {
          gem_name: ::Regexp.last_match(1).strip,
          current_version: ::Regexp.last_match(3).strip,
          latest_version: ::Regexp.last_match(2).strip
        }
      end

      total = lines_to_process.size

      # Process in parallel with threads (limit to 10 concurrent requests)
      mutex = Mutex.new
      thread_pool = []
      max_threads = 10

      lines_to_process.each_with_index do |line_data, index|
        # Wait if we have too many threads
        thread_pool.shift.join if thread_pool.size >= max_threads

        thread = Thread.new do
          # Fetch all version info once per gem (includes dates and version list)
          gem_data = fetch_gem_all_versions(line_data[:gem_name])

          # Extract dates for current and latest versions
          current_date = gem_data[:versions][line_data[:current_version]] || 'N/A'
          latest_date = gem_data[:versions][line_data[:latest_version]] || 'N/A'

          # Calculate time difference
          time_diff = calculate_time_difference(current_date, latest_date)

          # Count versions between current and latest
          version_count = count_versions_from_list(gem_data[:version_list], line_data[:current_version],
                                                   line_data[:latest_version])

          # Check if this is a direct dependency
          direct_dependency = is_direct_gem?(line_data[:gem_name])

          result = {
            gem: line_data[:gem_name],
            current: line_data[:current_version],
            current_date: current_date,
            latest: line_data[:latest_version],
            latest_date: latest_date,
            time_diff: time_diff,
            version_count: version_count,
            direct: direct_dependency,
            index: index
          }

          mutex.synchronize do
            versions << result
            print "\r📦 Checking Ruby gems... #{versions.size}/#{total}"
            $stdout.flush
          end
        end

        thread_pool << thread
      end

      # Wait for all threads to complete
      thread_pool.each(&:join)

      # Sort by original index to maintain order
      versions.sort_by! { |v| v[:index] }
      versions.each { |v| v.delete(:index) }

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

        # Process in parallel with threads (limit to 10 concurrent requests)
        mutex = Mutex.new
        thread_pool = []
        max_threads = 10

        packages_to_process.each_with_index do |pkg_data, index|
          # Wait if we have too many threads
          thread_pool.shift.join if thread_pool.size >= max_threads

          thread = Thread.new do
            # Fetch all version info once per package (includes dates and version list)
            pkg_data_full = fetch_npm_all_versions(pkg_data[:name])

            # Extract dates for current and latest versions
            current_date = pkg_data_full[:versions][pkg_data[:current_version]] || 'N/A'
            latest_date = pkg_data_full[:versions][pkg_data[:latest_version]] || 'N/A'

            # Calculate time difference
            time_diff = calculate_time_difference(current_date, latest_date)

            # Count versions between current and latest
            version_count = count_versions_from_list(pkg_data_full[:version_list], pkg_data[:current_version],
                                                     pkg_data[:latest_version])

            # Check if this is a direct dependency
            direct_dependency = is_direct_package?(pkg_data[:name])

            result = {
              package: pkg_data[:name],
              current: pkg_data[:current_version],
              current_date: current_date,
              latest: pkg_data[:latest_version],
              latest_date: latest_date,
              time_diff: time_diff,
              version_count: version_count,
              direct: direct_dependency,
              index: index
            }

            mutex.synchronize do
              versions << result
              print "\r📦 Checking NPM packages... #{versions.size}/#{total}"
              $stdout.flush
            end
          end

          thread_pool << thread
        end

        # Wait for all threads to complete
        thread_pool.each(&:join)

        # Sort by original index to maintain order
        versions.sort_by! { |v| v[:index] }
        versions.each { |v| v.delete(:index) }

        puts "\r📦 Checking NPM packages... #{total}/#{total} ✓" if total > 0
      end

      @result.package_versions = versions
    end

    def parse_yarn_outdated_output(output)
      versions = []
      packages_to_process = []

      # Yarn v1 outdated output format:
      # Package Name    Current Wanted Latest
      # package-name    1.0.0   1.0.0  2.0.0
      # Skip header lines and parse package info
      output.each_line do |line|
        line = line.strip
        next if line.empty?
        next if line.start_with?('Package') || line.start_with?('yarn') || line.start_with?('Done')
        next if line.include?('─') # Skip separator lines

        # Parse format: package-name    current    wanted    latest    location
        # Or: package-name    current    wanted    latest
        parts = line.split(/\s+/)
        next if parts.length < 4

        package_name = parts[0]
        current_version = parts[1]
        latest_version = parts[3] # Skip wanted (parts[2]), use latest

        # Skip if versions are the same (not outdated)
        next if current_version == latest_version

        packages_to_process << {
          name: package_name,
          current_version: current_version,
          latest_version: latest_version
        }
      end

      total = packages_to_process.size

      return if total == 0

      # Process in parallel with threads (limit to 10 concurrent requests)
      mutex = Mutex.new
      thread_pool = []
      max_threads = 10

      packages_to_process.each_with_index do |pkg_data, index|
        # Wait if we have too many threads
        thread_pool.shift.join if thread_pool.size >= max_threads

        thread = Thread.new do
          # Fetch all version info once per package (includes dates and version list)
          pkg_data_full = fetch_npm_all_versions(pkg_data[:name])

          # Extract dates for current and latest versions
          current_date = pkg_data_full[:versions][pkg_data[:current_version]] || 'N/A'
          latest_date = pkg_data_full[:versions][pkg_data[:latest_version]] || 'N/A'

          # Calculate time difference
          time_diff = calculate_time_difference(current_date, latest_date)

          # Count versions between current and latest
          version_count = count_versions_from_list(pkg_data_full[:version_list], pkg_data[:current_version],
                                                   pkg_data[:latest_version])

          # Check if this is a direct dependency
          direct_dependency = is_direct_package?(pkg_data[:name])

          result = {
            package: pkg_data[:name],
            current: pkg_data[:current_version],
            current_date: current_date,
            latest: pkg_data[:latest_version],
            latest_date: latest_date,
            time_diff: time_diff,
            version_count: version_count,
            direct: direct_dependency,
            index: index
          }

          mutex.synchronize do
            versions << result
            print "\r📦 Checking NPM packages... #{versions.size}/#{total}"
            $stdout.flush
          end
        end

        thread_pool << thread
      end

      # Wait for all threads to complete
      thread_pool.each(&:join)

      # Sort by original index to maintain order
      versions.sort_by! { |v| v[:index] }
      versions.each { |v| v.delete(:index) }

      puts "\r📦 Checking NPM packages... #{total}/#{total} ✓" if total > 0

      @result.package_versions = versions
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

    # Fetch all gem version info (dates and version list) from RubyGems API in one call
    def fetch_gem_all_versions(gem_name)
      return { versions: {}, version_list: [] } if gem_name.nil?

      uri = URI("https://rubygems.org/api/v1/versions/#{gem_name}.json")

      # Set timeout to avoid hanging
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification
      http.open_timeout = 2
      http.read_timeout = 3

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      return { versions: {}, version_list: [] } unless response.is_a?(Net::HTTPSuccess)

      all_versions = JSON.parse(response.body)

      # Build hash of version => date
      version_dates = {}
      version_list = []

      all_versions.each do |v|
        version_num = v['number']
        if v['created_at']
          date = DateTime.parse(v['created_at'])
          version_dates[version_num] = date.strftime('%-m/%-d/%Y')
        else
          version_dates[version_num] = 'N/A'
        end
        version_list << version_num
      end

      { versions: version_dates, version_list: version_list }
    rescue StandardError => e
      puts "  Debug: Error fetching versions for #{gem_name}: #{e.message}" if ENV['DEBUG']
      { versions: {}, version_list: [] }
    end

    # Count versions between current and latest from a version list
    def count_versions_from_list(version_list, current_version, latest_version)
      return 'N/A' if current_version == 'unknown' || latest_version == 'unknown' || version_list.empty?
      return 0 if current_version == latest_version

      # Find indices of current and latest versions
      current_idx = version_list.index(current_version)
      latest_idx = version_list.index(latest_version)

      return 'N/A' if current_idx.nil? || latest_idx.nil?

      # Count versions between (exclusive of current, inclusive of latest)
      (latest_idx - current_idx).abs
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
          "#{diff} day#{'s' if diff != 1}"
        elsif diff < 365
          months = (diff / 30.0).round
          "#{months} month#{'s' if months != 1}"
        else
          years = (diff / 365.0).round(1)
          if years == years.to_i
            "#{years.to_i} year#{'s' if years.to_i != 1}"
          else
            "#{years} years"
          end
        end
      rescue StandardError => e
        puts "  Debug: Error calculating time diff: #{e.message}" if ENV['DEBUG']
        'N/A'
      end
    end

    # Detect which package manager is available (npm or yarn)
    def detect_package_manager
      npm_available = check_command_available('npm')
      yarn_available = check_command_available('yarn')

      if npm_available && yarn_available
        # Both available - prompt user
        prompt_package_manager_choice
      elsif npm_available
        'npm'
      elsif yarn_available
        'yarn'
      else
        nil
      end
    end

    # Check if a command is available in the system
    def check_command_available(command)
      _, _, status = Open3.capture3("which #{command} 2>&1")
      status.success?
    rescue StandardError
      false
    end

    # Parse Gemfile to get direct dependencies
    def parse_gemfile
      return @direct_gems if @direct_gems

      gemfile_path = File.join(@project_path, 'Gemfile')
      return [] unless File.exist?(gemfile_path)

      direct_gems = []
      content = File.read(gemfile_path)

      # Match gem declarations: gem 'name', gem "name", gem('name'), gem("name")
      # Also handle version constraints and options
      content.scan(/^\s*gem\s+['"]([^'"]+)['"]/) do |match|
        gem_name = match[0]
        direct_gems << gem_name unless gem_name.nil?
      end

      @direct_gems = direct_gems.uniq
    end

    # Check if a gem is a direct dependency
    def is_direct_gem?(gem_name)
      parse_gemfile.include?(gem_name)
    end

    # Parse package.json to get direct dependencies
    def parse_package_json
      return @direct_packages if @direct_packages

      package_json_path = File.join(@project_path, 'package.json')
      return [] unless File.exist?(package_json_path)

      begin
        content = File.read(package_json_path)
        data = JSON.parse(content)

        # Get dependencies from dependencies, devDependencies, peerDependencies, optionalDependencies
        direct_packages = []
        %w[dependencies devDependencies peerDependencies optionalDependencies].each do |key|
          direct_packages.concat(data[key].keys) if data[key].is_a?(Hash)
        end

        @direct_packages = direct_packages.uniq
      rescue JSON::ParserError, Errno::ENOENT
        @direct_packages = []
      end
    end

    # Check if a package is a direct dependency
    def is_direct_package?(package_name)
      parse_package_json.include?(package_name)
    end

    # Prompt user to choose between npm and yarn when both are available
    def prompt_package_manager_choice
      puts "\n  Both npm and yarn are available. Which would you like to use?"
      print "  Enter 'n' for npm or 'y' for yarn (default: npm): "

      choice = $stdin.gets.chomp.strip.downcase

      if choice.empty? || choice == 'n' || choice == 'npm'
        'npm'
      elsif %w[y yarn].include?(choice)
        'yarn'
      else
        puts '  ⚠️  Invalid choice. Using npm as default.'
        'npm'
      end
    end

    # Fetch all NPM package version info (dates and version list) from NPM registry in one call
    def fetch_npm_all_versions(package_name)
      return { versions: {}, version_list: [] } if package_name.nil?

      # Encode package name for URL (handles scoped packages like @babel/core)
      encoded_name = URI.encode_www_form_component(package_name)
      uri = URI("https://registry.npmjs.org/#{encoded_name}")

      # Set timeout to avoid hanging
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification
      http.open_timeout = 2
      http.read_timeout = 3

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      return { versions: {}, version_list: [] } unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)

      return { versions: {}, version_list: [] } unless data['time'] && data['versions']

      # Build hash of version => date and sorted version list
      version_dates = {}
      version_times = data['time'].select { |k, v| k != 'created' && k != 'modified' && data['versions'][k] }

      # Sort versions by release date
      sorted_versions = version_times.sort_by { |k, v| DateTime.parse(v) }.map(&:first)

      # Build date hash
      version_times.each do |version, date_str|
        date = DateTime.parse(date_str)
        version_dates[version] = date.strftime('%-m/%-d/%Y')
      rescue StandardError
        version_dates[version] = 'N/A'
      end

      { versions: version_dates, version_list: sorted_versions }
    rescue StandardError => e
      puts "  Debug: Error fetching versions for #{package_name}: #{e.message}" if ENV['DEBUG']
      { versions: {}, version_list: [] }
    end
  end
end
