#!/usr/bin/ruby

##
# Class for tracking a backup task.
#
# Attributes:
#   @name (str): name of the task.
#   @interval (int): time in seconds between backups.
#   @local_copy (bool): keep a local copy or delete.
#   @paths (list): the file systems paths to backup.
#   @next_backup (Time): time of the next backup.
#   @current_backup (int): current backup iteration (count).
#
class BackupTask
  attr_accessor :name, :current_backup, :interval, :local_copy, :paths, :next_backup
  
  ##
  # Class initializer.
  # 
  # Parameters:
  #   task (Hash): contains the environment configuration.
  #
  def initialize task
    @name = task['name']
    @interval = task['interval']
    @local_copy = task['local_copy']
    @paths = task['paths']
    @next_backup = Time.now
    @current_backup = 0
  end
  
  # Increment the task time and iteration.
  def increment
    @next_backup = @next_backup + @interval
    @current_backup += 1
  end
  
  ##
  # String override.
  #
  # Returns: String
  #
  def to_s
    ("Name: #{@name}\n" \
     "Interval: #{@interval}\n" \
     "Next Backup: #{@next_backup}\n" \
     "Local Copy: #{@local_copy}\n" \
     "Paths: #{@paths}\n")
  end
end