# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/rubion'

class RubionTest < Minitest::Test
  def test_version
    refute_nil Rubion::VERSION
    assert_match(/\d+\.\d+\.\d+/, Rubion::VERSION)
  end

  def test_scanner_initialization
    scanner = Rubion::Scanner.new
    assert_instance_of Rubion::Scanner, scanner
  end

  def test_scan_result_structure
    scanner = Rubion::Scanner.new
    result = scanner.scan
    
    assert_respond_to result, :gem_vulnerabilities
    assert_respond_to result, :gem_versions
    assert_respond_to result, :package_vulnerabilities
    assert_respond_to result, :package_versions
  end

  def test_reporter_initialization
    scanner = Rubion::Scanner.new
    result = scanner.scan
    reporter = Rubion::Reporter.new(result)
    
    assert_instance_of Rubion::Reporter, reporter
  end
end



