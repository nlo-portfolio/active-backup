#!/usr/bin/ruby

require 'optparse'


##
# Module for parsing command line arguments.
#
module ArgParser
  ##
  # Parses the command line arguments.
  #
  # Parameters:
  #   args (list): the command line arguments.
  #
  # Returns: OpenStruct
  #
  def self.parse_args args
    options = OpenStruct.new
    #options.library = []
    #options.inplace = false
    #options.encoding = 'utf8'
    #options.transfer_type = :auto
    options.verbose = false
    options.decrypt = false
    options.untar = false
    options.unpack = false
    options.password = nil
    options.input_filename = nil
    options.output_filename = nil
    options.test = nil
    options.docker = nil
    options.config_file = nil

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: ruby active_backup.rb [options]'

      opts.separator ''
      opts.separator 'Options:'

      opts.on('-d', '--decrypt', 'Decrypt the archive (optional)') do
        options.decrypt = true
      end
      
      opts.on('-p', '--password [PASSWORD]', 'Password for archive') do |pword|
        options.password = pword
      end
      
      opts.on('-x', '--extract', 'eXtract the compressed file (optional)') do
        options.extract = true
      end
      
      opts.on('-t', '--untar', 'unTar the archive (optional)') do
        options.untar = true
      end
      
      opts.on('-u', '--unpack', 'Decrypt, extract and untar file (optional)') do
        options.unpack = true
      end
      
      opts.on('-i', '--input FILENAME', 'Input filename of the archive (required for decryption)') do |f|
        options.input_filename = f
      end
        
      opts.on('-o', '--output FILENAME', "Output filename for the decrypted/unTar'd archive (required for decryption)") do |f|
        options.output_filename = f
      end
        
      opts.on('-v', '--[no-]verbose', 'Output to the console (Optional)') do |v|
        options.verbose = v
      end
      
      opts.on('--docker-config', 'Use docker configuration (Dev Only)') do
        options.docker = true
      end
        
      opts.on( '-h', '--help', 'Display this screen (optional)' ) do
        puts opts
        exit 0
      end
    end
    
    opt_parser.parse!(args)
    if(options.decrypt || options.extract || options.untar || options.unpack) &&
      (options.input_filename.nil? || options.output_filename.nil?)
        raise OptionParser::MissingArgument.new 'Must specify input (-i) and output (-o) filename'
    end
    
    if(options.docker)
      options.config_file = File.expand_path File.dirname(__FILE__) + '/../docker-lib/config.docker.yml'
    else
      options.config_file = File.expand_path File.dirname(__FILE__) + '/../config.yml'
    end
    
    options
  end
end  
    