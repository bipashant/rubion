# frozen_string_literal: true

require_relative "rubion/version"
require_relative "rubion/scanner"
require_relative "rubion/reporter"

module Rubion
  class Error < StandardError; end

  class CLI
    def self.start(args)
      command = args[0]
      
      case command
      when 'scan'
        # Parse options
        options = parse_scan_options(args[1..-1])
        scan(options)
      when 'version', '-v', '--version'
        puts "Rubion version #{VERSION}"
      when 'help', '-h', '--help', nil
        print_help
      else
        puts "Unknown command: #{command}"
        print_help
        exit 1
      end
    end

    def self.parse_scan_options(args)
      options = { gems: true, packages: true }
      
      # Check for --gems-only or --packages-only flags
      if args.include?('--gems-only') || args.include?('-g')
        options[:gems] = true
        options[:packages] = false
      elsif args.include?('--packages-only') || args.include?('-p')
        options[:gems] = false
        options[:packages] = true
      elsif args.include?('--gems') || args.include?('--packages')
        # Legacy support for --gems and --packages
        options[:gems] = args.include?('--gems')
        options[:packages] = args.include?('--packages')
      end
      
      options
    end

    def self.scan(options = { gems: true, packages: true })
      project_path = Dir.pwd
      
      scanner = Scanner.new(project_path: project_path)
      result = scanner.scan_incremental(options)
      
      # Results are already printed incrementally based on options
      reporter = Reporter.new(result)
      
      # Only print package results if packages were scanned
      if options[:packages]
        reporter.print_package_vulnerabilities
        reporter.print_package_versions
      end
    end

    def self.print_help
      puts <<~HELP
        
        🔒 Rubion - Security & Version Scanner for Ruby and JavaScript projects
        
        USAGE:
          rubion scan [OPTIONS]       Scan current project for vulnerabilities and outdated versions
          rubion version              Display Rubion version
          rubion help                 Display this help message
        
        SCAN OPTIONS:
          --gems, --gem, -g           Scan only Ruby gems (skip NPM packages)
          --packages, --npm, -p       Scan only NPM packages (skip Ruby gems)
          --all, -a                   Scan both gems and packages (default)
        
        DESCRIPTION:
          Rubion scans your project for:
            - Ruby gem vulnerabilities (using bundler-audit)
            - Outdated Ruby gems (using bundle outdated)
            - NPM/JavaScript package vulnerabilities (using npm audit or yarn audit)
            - Outdated NPM/JavaScript packages (using npm outdated or yarn outdated)
        
        OUTPUT:
          Results are displayed in organized tables with:
            📛 Vulnerabilities with severity icons (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low)
            📦 Version information with release dates
            ⏱️  Time difference ("Behind By" column)
            🔢 Version count between current and latest
        
        EXAMPLES:
          # Scan both gems and packages (default)
          rubion scan
          
          # Scan only Ruby gems
          rubion scan --gems
          
          # Scan only NPM packages
          rubion scan --packages
          
          # Get help
          rubion help
        
        REQUIREMENTS:
          - Ruby 2.6+
          - Bundler (for gem scanning)
          - NPM or Yarn (for package scanning, optional)
          - bundler-audit (optional, install with: gem install bundler-audit)
          
        NOTE:
          If both npm and yarn are available, you will be prompted to choose which one to use.
        
      HELP
    end
  end
end

