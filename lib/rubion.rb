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
      # Default to sorting by "Behind By(Time)" in descending order
      options = { gems: true, packages: true, sort_by: "Behind By(Time)", sort_desc: true }
      
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
      
      # Parse --sort-by or -s option
      sort_index = args.index('--sort-by') || args.index('-s')
      if sort_index && args[sort_index + 1]
        options[:sort_by] = args[sort_index + 1]
      end
      
      # Parse --asc or --ascending for ascending order (descending is default)
      options[:sort_desc] = false if args.include?('--asc') || args.include?('--ascending')
      
      options
    end

    def self.scan(options = { gems: true, packages: true, sort_by: "Behind By(Time)", sort_desc: true })
      project_path = Dir.pwd
      
      scanner = Scanner.new(project_path: project_path)
      result = scanner.scan_incremental(options)
      
      # Results are already printed incrementally based on options
      # Package results are printed in scan_incremental, but we need to ensure
      # they use the same reporter instance with sort_by
      # Actually, scan_incremental handles gem printing, but package printing
      # happens here, so we need a reporter for packages
      if options[:packages]
        reporter = Reporter.new(result, sort_by: options[:sort_by], sort_desc: options[:sort_desc])
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
          --sort-by COLUMN, -s COLUMN Sort results by column (Name, Current, Date, Latest, Behind By(Time), Behind By(Versions))
                                     (default: "Behind By(Time)" in descending order)
          --asc, --ascending          Sort in ascending order (use with --sort-by)
        
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
          
          # Sort by name
          rubion scan --sort-by Name
          
          # Sort by versions behind
          rubion scan -s "Behind By(Versions)"
          
          # Sort by name in descending order (default)
          rubion scan --sort-by Name
          
          # Sort by name in ascending order
          rubion scan --sort-by Name --asc
          
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

