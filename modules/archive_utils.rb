#!/usr/bin/ruby

require 'fileutils'
require 'openssl'
require 'pathname'
require 'uri'
require 'zlib'
require 'rubygems/package'


##
# Module containing functions for converting data to tar format,
# compressing data to the gzip format, and encrypting data using
# OpenSSL.
#
module ArchiveUtils
  BLOCK_SIZE = 1024 * 1000
  
  ##
  # Write data from a list of paths to tar in memory.
  #
  # Parameters:
  #   paths  (Array):  contains the file directory paths to archive.
  #
  # Returns: StringIO
  #
  def self.archive(paths)
    tarfile = StringIO.new('')
    
    Gem::Package::TarWriter.new(tarfile) do |tar|
      Dir[*paths].each do |path|
        if File.directory?(path)
          mode = File.stat(path).mode
          relative_dir = URI(path).path.split('/')[-1]
          tar.mkdir relative_dir, mode
          
          Dir[File.join(path, "**/*")].each do |file|
            mode = File.stat(file).mode
            relative_file = file.sub /^#{Regexp::escape path}\/?/, ''
            
            if File.directory?(file)
              tar.mkdir relative_dir + '/' + relative_file, mode
            else
              tar.add_file relative_dir + '/' + relative_file, mode do |tf|
                File.open(file, 'rb') { |f| tf.write f.read }
              end
            end
          end
        else
          mode = File.stat(path).mode
          File.open(path, 'rb') do |f|
            tar.add_file_simple File.basename(path), mode, f.size do |tf|
              while buffer = f.read(BLOCK_SIZE)
                tf.write buffer
              end
            end
          end
        end
      end
    end

    tarfile.rewind
    #File.new('testfile.tar', 'wb+').write(tarfile.string)
    return tarfile
  end

  ##
  # Unarchive data to file.
  #
  # Parameters:
  #   io           (StringIO):  data to be archived.
  #   destination  (String):    output location.
  #
  # Returns: StringIO
  #
  def self.unarchive(io, destination)
    Gem::Package::TarReader.new io do |tar|
      tar.each do |tarfile|
        destination_file = File.join destination, tarfile.full_name

        if tarfile.directory?
          FileUtils.mkdir_p destination_file
        else
          destination_directory = File.dirname(destination_file)
          FileUtils.mkdir_p destination_directory unless File.directory?(destination_directory)
          File.open destination_file, 'wb' do |f|
            f.print tarfile.read BLOCK_SIZE
          end
        end
      end
    end
  end

  ##
  # Compress data to gzip in memory.
  #
  # Parameters:
  #   tarfile  (StringIO):  data to be compressed.
  #
  # Returns: StringIO
  #
  def self.compress tarfile
    gz = StringIO.new ''
    z = Zlib::GzipWriter.new(gz)
    while chunk = tarfile.read(BLOCK_SIZE)
      z.write chunk
    end
    z.close
    StringIO.new gz.string
  end
  
  ##
  # Decompress data to gzip in memory.
  #
  # Parameters:
  #   data  (StringIO):  data to be decompressed.
  #
  # Returns: StringIO
  #
  def self.decompress(data)
    gz = StringIO.new ''
    z = Zlib::GzipReader.new(data)
    while(!z.eof?)
      gz.write z.readpartial BLOCK_SIZE
    end
    z.close
    StringIO.new gz.string
  rescue => e
    throw 'Input not in gzip format.'
  end
  
  ##
  # Encrypt the archive.
  #
  # Parameters:
  #   task    (BackupTask):  task containing current paths to backup.
  #   intput  (StringIO):    data to be encrypted.
  #
  # Returns: String
  #
  def self.encrypt password, data
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = self.key_iter password

    #cipher.iv = '0' * 16
    #key = cipher.random_key
    #iv = cipher.random_iv
    #puts key
    #puts iv

    output = StringIO.new
    while chunk = data.read(BLOCK_SIZE)
      enc_data = cipher.update chunk
      output.write(enc_data)
    end
    output.write(cipher.final)
    output.rewind
    output
  end
  
  ##
  # Decrypt the archive.
  #
  # Parameters:
  #   task    (BackupTask):  task containing current paths to backup.
  #   intput  (StringIO):    data to be encrypted.
  #
  # Returns: String
  #
  def self.decrypt password, data
    output = StringIO.new ''
    decipher = OpenSSL::Cipher.new 'AES-256-CBC'
    decipher.decrypt
    decipher.key = self.key_iter password
    while chunk = data.read(BLOCK_SIZE)
      output.write decipher.update chunk
    end
    output.write decipher.final
    output.rewind
    output
  rescue
    raise 'Bad password or encryption format.'
  end
  
  ##
  # Unpack encrypted, archived and compressed files.
  # Operation order: Decrypt > Decompress > Unarchive
  #
  # Parameters:
  #   options  (OpenStruct):  command line options.
  #
  def self.unpack options
    o = nil
    file_s = File.open(options.input_filename)
    
    if options.decrypt || options.unpack
      o = self.decrypt options.password, file_s
    end
    
    if options.extract || options.unpack
      o ||= file_s
      o = self.decompress o
    end
    
    if options.untar || options.unpack
      o ||= file_s
      self.unarchive o, options.output_filename
    else
      self.write o, options.output_filename
    end
    puts 'Operation completed successfully.'
  rescue => e
    puts e
  end
  
  ##
  # Write data to storage.
  #
  # Parameters:
  #   input     (StringIO):  data to be written.
  #   filename  (String):    file to be written.
  #
  def self.write input, filename
    File.open(filename, 'w+') do |file_out|
      while chunk = input.gets
        file_out.write chunk
      end
    end
  end
  
  ##
  # Create a new password key.
  #
  # Parameters:
  #   key  (String):  key to be hashed.
  #
  # Returns: Digest::SHA256
  #
  def self.key_iter key
    digest = Digest::SHA256.digest(key)
    49999.times do
      digest = Digest::SHA256.digest(key)
    end
    digest
  end
end
