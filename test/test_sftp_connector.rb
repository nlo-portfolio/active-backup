#!/usr/bin/ruby

require 'rubygems'
require 'test/unit'
require 'mocha/test_unit'

require_relative 'fixtures/fixtures'
require_relative '../classes/sftp_connector'


class TestSFTPConnector < Test::Unit::TestCase
  
  def setup
    config = YAML.load(File.read(Fixtures.test_config))
    @sftp = SFTPConnector.new config['server'], Logger.new(STDOUT)
    @q = Queue.new
  end
  
  def teardown
  end
  
  def test_sftp_connection_should_pass
    assert_nothing_raised do
      Net::SFTP.stubs(:start).returns(nil)
      Net::SFTP.stubs(:upload!).returns(true)
      @sftp.transfer @q, 'files/test_file.txt'
    end
    assert @q.pop
  end
  
  def test_sftp_connection_refused_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(Errno::ECONNREFUSED)
      @sftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_sftp_connection_open_timeout_exception_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(Net::OpenTimeout)
      @sftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_sftp_connection_generic_exception_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(Net::SSH::Exception)
      @sftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_sftp_connection_bad_key_should_fail
    assert_nothing_raised do
      Net::SSH.stubs(:start).raises(OpenSSL::PKey::PKeyError)
      @sftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
end
