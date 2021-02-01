#!/usr/bin/ruby

require 'fileutils'
require 'ostruct'
require 'yaml'
require 'test/unit'

require_relative 'fixtures/fixtures'
require_relative '../classes/backup_manager'
require_relative '../modules/archive_utils'


class ArhiveUtilsTest < Test::Unit::TestCase

  def setup
    @config = YAML.load(File.read(Fixtures.test_config))
    @test_password = Fixtures.test_password
    @manager = BackupManager.new @config
  
    # Redirect stdout/stderr.
    @original_stdout = $stdout.dup
    @original_stderr = $stderr.dup
    $stdout.reopen("/dev/null", "w")
    $stderr.reopen("/dev/null", "w")
  end
  
  def teardown
    # Redirect output back to stdout/stderr.
    $stdout.reopen(@original_stdout)
    $stderr.reopen(@original_stderr)
    
    # Delete all unecessary temporary test files.
    Dir.foreach(Fixtures.temp_base) do |f|
      fn = File.join(Fixtures.temp_base, f)
      FileUtils.rm_r(fn) if f != '.' && f != '..'
    end
  end
  
  def test_encryption_should_pass
    ciphertext = ArchiveUtils.encrypt @test_password, StringIO.new(Fixtures.test_plaintext)
    assert_equal Fixtures.test_ciphertext.force_encoding('UTF-8'), ciphertext.string
  end
  
  def test_decryption_should_pass
    plaintext = ArchiveUtils.decrypt @test_password, StringIO.new(Fixtures.test_ciphertext)
    assert_equal Fixtures.test_plaintext, plaintext.string
  end
  
  def test_decryption_invalid_password_should_fail
    #assert_raise_message(RuntimeError, 'Bad password or encryption format.') do
    assert_raises RuntimeError do
      ArchiveUtils.decrypt 'invalid password', Fixtures.test_ciphertext
    end
  end
  
  def test_decryption_invalid_format_should_fail
    #assert_raise_message(RuntimeError, 'Bad password or encryption format.') do
    assert_raises RuntimeError do
      ArchiveUtils.decrypt @test_password, ''
    end
  end
  
  def test_compression_should_pass
    compressed = ArchiveUtils.compress StringIO.new(Fixtures.test_plaintext)
    assert_not_equal compressed, Fixtures.test_plaintext
    z = Zlib::GzipReader.new(compressed)
    decompressed = StringIO.new(z.read)
    z.close
    assert_equal Fixtures.test_plaintext, decompressed.string
  end
  
  def test_decompress_should_pass
    compressed_io = ArchiveUtils.compress StringIO.new(Fixtures.test_plaintext)
    decompressed_io = ArchiveUtils.decompress compressed_io
    assert_equal Fixtures.test_plaintext, decompressed_io.string
  end
  
  def test_decompress_should_fail
    #assert_raise_message(UncaughtThrowError, 'Input not in gzip format.') do
    assert_raises UncaughtThrowError do
      decompressed = ArchiveUtils.decompress StringIO.new('')
    end
  end
  
  def test_archive_should_pass
    archive_io = ArchiveUtils.archive [Fixtures.fixtures_base + '/test_dir_official', Fixtures.fixtures_base + '/test_dir_official2', Fixtures.fixtures_base + '/test_file']
    unarchive = ArchiveUtils.unarchive archive_io, Fixtures.temp_base
    
    # Assert first test directory is unarchived in root folder.
    assert File.directory? Fixtures.temp_base + '/test_dir_official'
    assert File.directory? Fixtures.temp_base + '/test_dir_official/test_dir'
    assert File.directory? Fixtures.temp_base + '/test_dir_official/test_dir/test_dir2'
    assert File.directory? Fixtures.temp_base + '/test_dir_official/test_dir/test_dir3'
    assert File.exist? Fixtures.temp_base + '/test_dir_official/test_dir/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir_official/test_dir/testfile2'
    assert File.exist? Fixtures.temp_base + '/test_dir_official/test_dir/test_dir2/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir_official/test_dir/test_dir2/testfile2'
    assert File.exist? Fixtures.temp_base + '/test_dir_official/test_dir/test_dir3/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir_official/test_dir/test_dir3/testfile2'
    
    # Assert second test directory is unarchived in root folder.
    assert File.directory? Fixtures.temp_base + '/test_dir_official2'
    assert File.directory? Fixtures.temp_base + '/test_dir_official2/test_dir'
    assert File.directory? Fixtures.temp_base + '/test_dir_official2/test_dir/test_dir2'
    assert File.directory? Fixtures.temp_base + '/test_dir_official2/test_dir/test_dir3'
    assert File.exist? Fixtures.temp_base + '/test_dir_official2/test_dir/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir_official2/test_dir/testfile2'
    assert File.exist? Fixtures.temp_base + '/test_dir_official2/test_dir/test_dir2/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir_official2/test_dir/test_dir2/testfile2'
    assert File.exist? Fixtures.temp_base + '/test_dir_official2/test_dir/test_dir3/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir_official2/test_dir/test_dir3/testfile2'
    
    # Assert test file is unarchived in root folder.
    assert File.exist? Fixtures.temp_base + '/test_file'
  end
  
  def test_archive_should_fail
    assert_nil ArchiveUtils.unarchive StringIO.new(''), Fixtures.temp_base
  end
  
  def test_unarchive_should_pass
    test_archive = StringIO.new File.read(Fixtures.fixtures_base + '/test_dir_official.tar')
    test_archive.binmode
    ArchiveUtils.unarchive test_archive, Fixtures.temp_base
    assert File.directory? Fixtures.temp_base + '/test_dir'
    assert File.directory? Fixtures.temp_base + '/test_dir/test_dir2'
    assert File.directory? Fixtures.temp_base + '/test_dir/test_dir3'
    assert File.exist? Fixtures.temp_base + '/test_dir/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir/testfile2'
    assert File.exist? Fixtures.temp_base + '/test_dir/test_dir2/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir/test_dir2/testfile2'
    assert File.exist? Fixtures.temp_base + '/test_dir/test_dir3/testfile1'
    assert File.exist? Fixtures.temp_base + '/test_dir/test_dir3/testfile2'
  end
  
  def test_unarchive_should_fail
    assert_equal '', ArchiveUtils.archive(['invalid_path']).string.gsub(/\u0000/, '')
  end
  
  def test_unpack_decrypt_only_should_pass
    options = OpenStruct.new
    options.decrypt = true
    options.password = 'test'
    options.input_filename = Fixtures.fixtures_base + '/test_file.enc'
    options.output_filename = Fixtures.temp_base + '/test_decryption.dec'
    ArchiveUtils.unpack options
    assert File.exist? options.output_filename
    assert_equal File.read(Fixtures.fixtures_base + '/test_file'), File.read(options.output_filename)
  end
  
  def test_unpack_decompress_only_should_pass
    options = OpenStruct.new
    options.extract = true
    options.input_filename = Fixtures.fixtures_base + '/test_dir_official.tar.gz'
    options.output_filename = Fixtures.temp_base + '/test_decompression.tar'
    ArchiveUtils.unpack options
    assert File.exist? options.output_filename
  end
  
  def test_unpack_unarchive_only_should_pass
    options = OpenStruct.new
    options.untar = true
    options.input_filename = Fixtures.fixtures_base + '/test_dir_official.tar'
    options.output_filename = Fixtures.temp_base + '/test_unarchive'
    ArchiveUtils.unpack options
    assert File.exist? options.output_filename
    assert File.directory? options.output_filename
  end
  
  def test_unpack_all_should_pass
    options = OpenStruct.new
    options.unpack = true
    options.password = 'test'
    options.input_filename = Fixtures.fixtures_base + '/test_dir_official.tar.gz.enc'
    options.output_filename = Fixtures.temp_base + '/test_unpack'
    ArchiveUtils.unpack options
    assert File.exist? options.output_filename
    assert File.directory? options.output_filename
    assert File.directory? options.output_filename + '/test_dir'
    assert File.directory? options.output_filename + '/test_dir/test_dir2'
    assert File.directory? options.output_filename + '/test_dir/test_dir3'
    assert File.exist? options.output_filename + '/test_dir/testfile1'
    assert File.exist? options.output_filename + '/test_dir/test_dir2/testfile1'
    assert File.exist? options.output_filename + '/test_dir/test_dir2/testfile2'
    assert File.exist? options.output_filename + '/test_dir/test_dir3/testfile1'
    assert File.exist? options.output_filename + '/test_dir/test_dir3/testfile2'
    #assert_equal test_text, File.read(options.output_filename + '/test_dir/test_dir2/testfile1')
  end
end
