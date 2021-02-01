#!/usr/bin/ruby

require 'logger'
require 'rubygems'
require 'test/unit'
require 'mocha/test_unit'

require_relative 'fixtures/fixtures'
require_relative '../classes/ftp_connector'


class TestFTPConnector < Test::Unit::TestCase
  
  def setup
    config = YAML.load(File.read(Fixtures.test_config))
    @ftp = FTPConnector.new config['server'], Logger.new(STDOUT)
    @q = Queue.new
  end
  
  def teardown
  end
  
  def test_ftp_connection_should_pass
    assert_nothing_raised do
      Net::FTP.stubs(:open).returns(nil)
      Net::FTP.stubs(:putbinaryfile).returns(true)
      @ftp.transfer @q, 'files/test_file.txt'
    end
    assert @q.pop
  end
  
  def test_ftp_connection_refused_should_fail
    assert_nothing_raised do
      Net::FTP.stubs(:open).raises(Errno::ECONNREFUSED)
      #Net::FTP.stubs(:putbinaryfile).raises(Errno::ECONNREFUSED)
      @ftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_ftp_connection_generic_exception_should_fail
    assert_nothing_raised do
      Net::FTP.stubs(:open).raises(StandardError)
      @ftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_ftp_connection_open_timeout_exception_should_fail
    assert_nothing_raised do
      Net::FTP.stubs(:open).raises(Net::OpenTimeout)
      @ftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
  
  def test_ftp_connection_bad_password_should_fail
    assert_nothing_raised do
      Net::FTP.stubs(:open).raises(Net::FTPPermError)
      @ftp.transfer @q, 'files/test_file.txt'
    end
    refute @q.pop
  end
end
