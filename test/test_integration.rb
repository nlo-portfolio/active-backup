#!/usr/bin/ruby

require 'net/http'
require 'open3'
require 'test/unit'
require 'yaml'

require_relative 'fixtures/fixtures'


class ActiveBackupIntegrationTest < Test::Unit::TestCase
  
  def setup
    @config = YAML.load(File.read(Fixtures.test_config))
    
    # Redirect stdout/stderr.
    @original_stdout = $stdout.dup
    @original_stderr = $stderr.dup
    $stdout.reopen("/dev/null", "w")
    $stderr.reopen("/dev/null", "w")
  end
  
  def teardown
    # Redirect output back to stdout.
    $stdout.reopen(@original_stdout)
    $stderr.reopen(@original_stderr)
  end
  
  # NOT YET IMPLEMENTED.
  def test_integration
  end
end
