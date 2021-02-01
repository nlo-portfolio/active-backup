#!/usr/bin/ruby

require 'yaml'
require 'io/console'
require 'ostruct'
#require 'pp'
#require 'highline/import'

require_relative 'classes/backup_manager'
require_relative 'modules/argparser'
require_relative 'modules/archive_utils'


##
# Main driver.
# Will prompt the user for the archive password if not
# supplied in the configuration.
#
def main
  options = nil
  if ARGV
    begin
      options = ArgParser.parse_args(ARGV)
    rescue => e
      puts e.message
      exit 1
    end
  end
  
  begin
    config = YAML.load(File.read(options.config_file))
  rescue Errno::ENOENT
    puts "Config file not found: '#{options.config_file}'"
    exit 1
  end
  
  if options.unpack || options.decrypt || options.extract || options.untar
    if ((options.unpack || options.decrypt) && options.password.nil?)
      options.password = STDIN.getpass('Archive Password (hidden): ')
    end
    ArchiveUtils.unpack(options)
    exit 0
  end

  if config['env']['encrypt'] and not config['env']['archive_password']
    loop do
      #pword_one = ask('Archive password: ') { |q| q.echo = "*" }
      #pword_two = ask('Confirm password: ') { |q| q.echo = "*" }
      pword_one = STDIN.getpass("Archive Password (hidden): ")
      pword_two = STDIN.getpass("Confirm Password (hidden): ")
    
      if pword_one == pword_two
        config['env']['archive_password'] = pword_one
        break
      else
        puts 'Passwords do not match. Try again.'
      end
    end
  end
  
  manager = BackupManager.new config, Logger.new(STDOUT)
  manager.run
rescue ArgumentError => e
  puts e
end

main