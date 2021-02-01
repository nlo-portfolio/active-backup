#!/usr/bin/ruby

require 'rubygems'
require 'test/unit'
require 'mocha/test_unit'

require_relative 'fixtures/fixtures'
require_relative '../classes/scp_connector'


class TestSCPConnector < Test::Unit::TestCase
  
  def setup
    config = YAML.load(File.read(Fixtures.test_config))
    @scp = SCPConnector.new config['server'], Logger.new(STDOUT)
    @q = Queue.new
  end
  
  def teardown
  end
  
  def test_scp_connection_should_pass
    assert_nothing_raised do
      Net::SSH.stubs(:start).returns(nil)
      Net::SSH.stubs(:upload!).returns(true)
      @scp.transfer @q, 'files/test_file.txt'
    end
    assert @q.pop
  end
  
  def test_scp_connection_refused_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(Errno::ECONNREFUSED)
      @scp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_scp_connection_open_timeout_exception_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(Net::OpenTimeout)
      @scp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_scp_connection_generic_exception_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(Net::SSH::Exception)
      @scp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_scp_connection_bad_key_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(OpenSSL::PKey::PKeyError)
      @scp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
end
