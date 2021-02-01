#!/usr/bin/ruby

require 'openssl'
require 'thread'

require_relative 'backup_task'
require_relative 'ftp_connector'
require_relative 'sftp_connector'
require_relative 'scp_connector'
require_relative '../modules/archive_utils'


##
# Manages backups and scheduling.
#
# Attributes:
#   @logger (Logging object): logging object for messages.
#   @connector (SSHConnector): connection to use for transfers.
#   @tasks (list): list of backup tasks.
#
class BackupManager
  attr_accessor :tasks
  
  ##
  # Class initializer.
  #
  # Parameters:
  #   config (Hash): program settings.
  #   logger (logger): logging object for messages.
  #
  def initialize config, logger=nil
    @config = config
    @tasks = []
    config['tasks'].each { | task | @tasks << BackupTask.new(task) }
    
    #@logger = Logger.new('log/backup.log', 10, 1024000)
    @logger = Logger.new(STDOUT, 10, 1024000)
          
    #@logger = nil
    #if config['env']['logfile']
    #  @logger = Logger.new('log/backup.log', 10, 1024000)
    #else
    #  @logger = Logger.new(STDOUT, 10, 1024000)
    #end
    @logger.level = Logger::INFO
      
    
    @connector = nil
    if config['server']['type'] == 'ftp'
      @connector = FTPConnector.new config['server'], @logger
    elsif config['server']['type'] == 'sftp'
      @connector = SFTPConnector.new config['server'], @logger
    elsif config['server']['type'] == 'scp'
      @connector = SCPConnector.new config['server'], @logger
    else
      raise ArgumentError.new (
        'Invalid connection type. Please see the configuration file for acceptable types.'
      )
    end
  end
  
  ##
  # Main driver with infinite loop.
  #
  def run
    loop do
      sleep(backup)
    end
  # Rescue unexpected errors for long-term running.
  rescue => e
    @logger.error e.message
    e.backtrace.each { |line| @logger.error line }
  end
  
  ##
  # Archive, compress, encrypt and transfer the backup.
  #
  # Returns: Integer
  #
  def backup
    @logger.info 'Running backup...'
    threads = []
    q = Queue.new
    @tasks.each do |task|
      if task.next_backup < Time.now
        output = ArchiveUtils.archive task.paths
        output = ArchiveUtils.compress output
        ext = ''
        if @config['env']['encrypt']
          output = ArchiveUtils.encrypt( 
            @config['env']['archive_password'], output
          )
          ext = '.enc'
        end
        filename = "local_copies/#{task.name.gsub(/[^\w\.]/, '_')}-" \
                                "#{task.current_backup}.tar.gz#{ext}"
        
        ArchiveUtils.write output, filename
        threads << Thread.new { @connector.transfer q, filename }
        task.increment
      end
    end
    threads.each(&:join)
    
    success = 0
    failed = 0
    threads.count do
      result = q.pop
      if result then success += 1 else failed += 1 end
    end
    
    @logger.info "Backup complete: #{Time.now}. #{@tasks.count} tasks run. #{success} successful, #{failed} failures."
    next_backup
  end
  
  ##
  # Return time in seconds until the next backup task.
  #
  # Returns: Integer
  #
  def next_backup
    next_task = Time.new(3000)  # Set time to year 3000.
    @tasks.each do |task|
      if task.next_backup < next_task
        next_task = task.next_backup
      end
    end
    
    ntime = (next_task - Time.now)
    # Check for negative integers.
    if ntime < 0 then ntime = 0 end
    @logger.info "Sleeping: #{(ntime.round(2))} seconds..."
    ntime
  end
end