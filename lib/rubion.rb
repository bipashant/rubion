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
        scan
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

    def self.scan
      project_path = Dir.pwd
      
      scanner = Scanner.new(project_path: project_path)
      result = scanner.scan
      
      reporter = Reporter.new(result)
      reporter.report
    end

    def self.print_help
      puts <<~HELP
        
        🔒 Rubion - Security & Version Scanner for Ruby and JavaScript projects
        
        USAGE:
          rubion scan                 Scan current project for vulnerabilities and outdated versions
          rubion version              Display Rubion version
          rubion help                 Display this help message
        
        DESCRIPTION:
          Rubion scans your project for:
            - Ruby gem vulnerabilities (using bundler-audit)
            - Outdated Ruby gems (using bundle outdated)
            - NPM package vulnerabilities (using npm audit)
            - Outdated NPM packages (using npm outdated)
        
        OUTPUT:
          Results are displayed in organized tables:
            📛 Gem Vulnerabilities
            📦 Gem Versions (Outdated)
            📛 NPM Package Vulnerabilities
            📦 NPM Package Versions (Outdated)
        
        EXAMPLES:
          # Scan current directory
          rubion scan
          
          # Get help
          rubion help
        
        REQUIREMENTS:
          - Ruby 2.6+
          - Bundler (for gem scanning)
          - NPM (for package scanning, optional)
          - bundler-audit (optional, install with: gem install bundler-audit)
        
      HELP
    end
  end
end

