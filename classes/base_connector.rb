#!/usr/bin/ruby

##
# Manages backups and scheduling.
#
# Attributes:
#   @name         (String):  name of the backup jobs.
#   @type         (String):  type of connector.
#   @ip           (String):  IP address of the target upload server.
#   @username     (String):  username for upload server authentication.
#   @dest_folder  (String):  destination folder for upload on the server.
#   @logger       (Logger):  logging object for messages.
#
class BaseConnector

  ##
  # Class initializer.
  #
  # Parameters:
  #   server_config  (Hash):    configuration with server settings.
  #   logger         (Logger):  logging object for messages.
  #
  def initialize server_config, logger
    @name = server_config['name']
    @type = server_config['type']
    @ip = server_config['ip']
    @port = server_config['port']
    @username = server_config['username']
    @password = server_config['password']
    @dest_folder = server_config['dest_folder']
    @timeout = server_config['timeout'] || 30
    
    if server_config['seperate_logfile']
      @logger = Logger.new 'log/transfer.log'
    else
      @logger = logger
    end
  end
  
  ##
  # String override.
  #
  # Returns: String
  #
  def to_s
    ("Name: #{@name}\n" \
     "Type: #{@type}\n" \
     "IP: #{@ip}\n" \
     "Username: #{@username}\n" \
     "Destination Folder: #{@dest_folder}\n")
     #puts "Private Key: #{@private_key}"
  end
end