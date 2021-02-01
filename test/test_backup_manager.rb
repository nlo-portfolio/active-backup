#!/usr/bin/ruby

require 'yaml'
require 'test/unit'

require_relative 'fixtures/fixtures'
require_relative '../classes/backup_manager'


class BackupManagerTest < Test::Unit::TestCase
  def setup
    @config = YAML.load(File.read(Fixtures.test_config))
    @manager = BackupManager.new @config
  
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
  
  def test_backup_should_pass
    assert_nothing_raised do
      @manager.backup
    end
  end
  
  def test_next_backup_should_pass
    @manager.tasks[0].next_backup = Time.new + @config['tasks'][0]['interval']
    # @manager.tasks[1].next_backup = Time.new + @config['tasks'][0]['interval']
    ntime = @manager.backup
    assert_in_delta @config['tasks'][0]['interval'], ntime, 0.1
  end
  
  # First run should always execute all backup tasks immediatelly.
  def test_next_backup_first_run_should_pass
    ntime = @manager.next_backup
    assert_equal 0, ntime
  end
end
